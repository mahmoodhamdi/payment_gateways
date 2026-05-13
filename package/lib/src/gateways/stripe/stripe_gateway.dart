import 'package:flutter/material.dart';
import 'package:payment_gateways/src/backend/backend_client.dart';
import 'package:payment_gateways/src/core/currency.dart';
import 'package:payment_gateways/src/core/gateway_config.dart';
import 'package:payment_gateways/src/core/gateway_metadata.dart';
import 'package:payment_gateways/src/core/payment_error.dart';
import 'package:payment_gateways/src/core/payment_gateway.dart';
import 'package:payment_gateways/src/core/payment_intent.dart';
import 'package:payment_gateways/src/core/payment_method.dart';
import 'package:payment_gateways/src/core/payment_result.dart';
import 'package:payment_gateways/src/core/payment_status.dart';
import 'package:payment_gateways/src/payment_gateways_facade.dart';
import 'package:payment_gateways/src/ui/card_input.dart';
import 'package:payment_gateways/src/ui/payment_gateways_theme.dart';
import 'package:payment_gateways/src/ui/three_ds_webview.dart';
import 'package:payment_gateways/src/utils/logger.dart';

/// Stripe adapter. The actual secret-key API calls happen on the backend
/// companion; this adapter orchestrates the UI side of the flow (collect
/// card, hand to backend, present 3DS WebView).
class StripeGateway implements PaymentGateway {
  StripeGateway({
    required this.config,
    required this.backend,
    required this.logger,
  });

  factory StripeGateway.build(
    Object config,
    BackendClient backend,
    PaymentLogger logger,
  ) {
    if (config is! StripeConfig) {
      throw ConfigError(
        details: 'Expected StripeConfig but got ${config.runtimeType}',
      );
    }
    return StripeGateway(config: config, backend: backend, logger: logger);
  }

  /// Use as one of the `gatewayBuilders` on `PaymentGateways`.
  static const GatewayBuilder builder = GatewayBuilder(
    gatewayId: 'stripe',
    build: StripeGateway.build,
  );

  /// Reserved URL the backend redirects to on a successful 3DS challenge.
  /// Must match the same constant on the backend.
  static const String successUrlPrefix =
      'https://payment-gateways.local/stripe/success';

  /// Reserved URL the backend redirects to on a failed 3DS challenge.
  static const String failureUrlPrefix =
      'https://payment-gateways.local/stripe/failure';

  final StripeConfig config;
  final BackendClient backend;
  final PaymentLogger logger;

  @override
  String get id => 'stripe';

  @override
  GatewayMetadata get metadata => GatewayMetadata(
        id: 'stripe',
        displayName: 'Stripe',
        supportedCurrencies: {
          Currency.usd,
          Currency.eur,
          Currency.gbp,
          Currency.aed,
          Currency.sar,
          Currency.egp,
        },
        supportedRegions: const {}, // global
        supportsWallets: true,
        supportsSubscriptionsNatively: true,
      );

  @override
  bool supports(PaymentMethod method) => switch (method) {
        CardPaymentMethod() => true,
        WalletPaymentMethod(:final type) => switch (type) {
            WalletType.applePay ||
            WalletType.googlePay ||
            WalletType.link =>
              true,
            _ => false,
          },
        _ => false,
      };

  @override
  Future<PaymentResult> initiate({
    required PaymentIntent intent,
    required PaymentMethod method,
    required BuildContext context,
  }) async {
    if (!supports(method)) {
      return PaymentResult.failure(
        error: GatewayUnavailableError(
          gateway: id,
          gatewayMessage: 'Stripe does not support method ${method.kind}',
        ),
      );
    }

    final created = await backend.createIntent(intent: intent, gatewayId: id);
    if (created.gatewayIntentId == null) {
      return const PaymentResult.failure(
        error: ConfigError(
          details:
              'Backend did not return Stripe gateway_intent_id. '
              'Check your /api/checkout endpoint.',
        ),
      );
    }

    if (!context.mounted) return const PaymentResult.canceled();

    return switch (method) {
      CardPaymentMethod() => _runCardFlow(created, context),
      WalletPaymentMethod() => _runWalletFlow(created, method, context),
      _ => PaymentResult.failure(
          error: GatewayUnavailableError(
            gateway: id,
            gatewayMessage: 'unreachable',
          ),
        ),
    };
  }

  Future<PaymentResult> _runCardFlow(
    PaymentIntent intent,
    BuildContext context,
  ) async {
    final card = await _showCardSheet(context);
    if (card == null) return const PaymentResult.canceled();

    try {
      final response = await backend.confirmCard(
        gatewayId: id,
        gatewayIntentId: intent.gatewayIntentId!,
        rawCard: card,
        successUrl: successUrlPrefix,
        failureUrl: failureUrlPrefix,
      );

      switch (response.status) {
        case PaymentStatus.succeeded:
          return PaymentResult.success(
            transactionId: response.transactionId ?? intent.gatewayIntentId!,
            gatewayName: id,
          );
        case PaymentStatus.requires3ds:
          if (response.actionUrl == null) {
            return const PaymentResult.failure(
              error: ThreeDSecureFailedError(),
            );
          }
          if (!context.mounted) return const PaymentResult.canceled();
          return _completeThreeDs(
            actionUrl: response.actionUrl!,
            transactionId:
                response.transactionId ?? intent.gatewayIntentId!,
            context: context,
          );
        case PaymentStatus.failed:
          return PaymentResult.failure(
            error: response.error ?? const CardDeclinedError(),
          );
        case PaymentStatus.pending:
        case PaymentStatus.processing:
        case PaymentStatus.requiresExternalAction:
        case PaymentStatus.canceled:
        case PaymentStatus.refunded:
          return PaymentResult.success(
            transactionId: response.transactionId ?? intent.gatewayIntentId!,
            gatewayName: id,
          );
      }
    } on PaymentError catch (e) {
      return PaymentResult.failure(error: e);
    } catch (e, stack) {
      logger.error('Stripe card flow failed', error: e, stackTrace: stack);
      return PaymentResult.failure(error: UnknownError(cause: e));
    }
  }

  Future<PaymentResult> _completeThreeDs({
    required Uri actionUrl,
    required String transactionId,
    required BuildContext context,
  }) async {
    if (!context.mounted) return const PaymentResult.canceled();
    final passed = await ThreeDSWebView.show(
      context,
      actionUrl: actionUrl,
      successUrlPrefix: successUrlPrefix,
      failureUrlPrefix: failureUrlPrefix,
      title: 'Verify your card',
    );
    if (passed ?? false) {
      return PaymentResult.success(
        transactionId: transactionId,
        gatewayName: id,
      );
    }
    if (passed == false) {
      return const PaymentResult.failure(error: ThreeDSecureFailedError());
    }
    return const PaymentResult.canceled();
  }

  Future<RawCardDetails?> _showCardSheet(BuildContext context) {
    return showModalBottomSheet<RawCardDetails>(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) {
        final t = PaymentGatewaysTheme.of(sheetCtx);
        return Padding(
          padding: EdgeInsets.only(
            left: t.horizontalPadding,
            right: t.horizontalPadding,
            top: t.verticalGap * 2,
            bottom:
                MediaQuery.of(sheetCtx).viewInsets.bottom + t.verticalGap * 2,
          ),
          child: CardInput(
            onSubmit: (details) => Navigator.of(sheetCtx).pop(details),
            collectCardholderName: true,
            submitButtonLabel: 'Confirm payment',
          ),
        );
      },
    );
  }

  Future<PaymentResult> _runWalletFlow(
    PaymentIntent intent,
    PaymentMethod method,
    BuildContext context,
  ) async {
    // Stripe Apple Pay / Google Pay / Link require platform-native sheets
    // wired through `flutter_stripe`. Until v1.1 ships that integration,
    // surface a clear ConfigError so the integrator can route around it.
    logger.warn(
      'Stripe wallet flow not yet wired in v0.1 — fall back to card',
    );
    return const PaymentResult.failure(
      error: ConfigError(
        details:
            'Stripe wallet flows (Apple Pay / Google Pay / Link) require the '
            'flutter_stripe plugin (planned for v1.1). For now, pass '
            'method: PaymentMethod.card() instead.',
      ),
    );
  }

  @override
  Future<PaymentResult> refund({
    required String transactionId,
    int? amountMinorUnits,
  }) async {
    try {
      final ok = await backend.refund(
        transactionId: transactionId,
        gatewayId: id,
        amountMinorUnits: amountMinorUnits,
      );
      if (!ok) {
        return PaymentResult.failure(
          error: GatewayUnavailableError(
            gateway: id,
            gatewayMessage: 'Refund rejected.',
          ),
        );
      }
      return PaymentResult.success(
        transactionId: transactionId,
        gatewayName: id,
      );
    } on PaymentError catch (e) {
      return PaymentResult.failure(error: e);
    }
  }

  @override
  Future<PaymentStatus> getStatus({required String transactionId}) {
    return backend.getStatus(transactionId: transactionId, gatewayId: id);
  }
}
