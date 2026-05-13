import 'package:flutter/widgets.dart';
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
import 'package:payment_gateways/src/core/region.dart';
import 'package:payment_gateways/src/payment_gateways_facade.dart';
import 'package:payment_gateways/src/ui/three_ds_webview.dart';
import 'package:payment_gateways/src/utils/logger.dart';

/// Square adapter — US / UK / CA / AU.
///
/// v0.1 implementation routes the full flow through the backend (Square's
/// Web Payments SDK is loaded by the backend as a hosted iframe).
/// Native Square Mobile Payments SDK integration is planned for v1.1.
class SquareGateway implements PaymentGateway {
  SquareGateway({
    required this.config,
    required this.backend,
    required this.logger,
  });

  factory SquareGateway.build(
    Object config,
    BackendClient backend,
    PaymentLogger logger,
  ) {
    if (config is! SquareConfig) {
      throw ConfigError(
        details: 'Expected SquareConfig but got ${config.runtimeType}',
      );
    }
    return SquareGateway(config: config, backend: backend, logger: logger);
  }

  static const GatewayBuilder builder = GatewayBuilder(
    gatewayId: 'square',
    build: SquareGateway.build,
  );

  static const String successUrlPrefix =
      'https://payment-gateways.local/square/success';
  static const String failureUrlPrefix =
      'https://payment-gateways.local/square/failure';

  final SquareConfig config;
  final BackendClient backend;
  final PaymentLogger logger;

  @override
  String get id => 'square';

  @override
  GatewayMetadata get metadata => GatewayMetadata(
        id: 'square',
        displayName: 'Square',
        supportedCurrencies: {Currency.usd, Currency.gbp},
        supportedRegions: {
          Region.us,
          Region.gb,
          Region.ca,
          Region.au,
        },
        supportsWallets: true,
      );

  @override
  bool supports(PaymentMethod method) => switch (method) {
        CardPaymentMethod() => true,
        WalletPaymentMethod(:final type) =>
          type == WalletType.applePay || type == WalletType.googlePay,
        _ => false,
      };

  @override
  Future<PaymentResult> initiate({
    required PaymentIntent intent,
    required PaymentMethod method,
    required BuildContext context,
  }) async {
    final created = await backend.createIntent(intent: intent, gatewayId: id);
    final checkoutUrl = created.clientSecret;
    if (checkoutUrl == null) {
      return const PaymentResult.failure(
        error: ConfigError(
          details: 'Backend did not return Square checkout URL.',
        ),
      );
    }
    if (!context.mounted) return const PaymentResult.canceled();
    final passed = await ThreeDSWebView.show(
      context,
      actionUrl: Uri.parse(checkoutUrl),
      successUrlPrefix: successUrlPrefix,
      failureUrlPrefix: failureUrlPrefix,
      title: 'Square Checkout',
    );
    if (passed ?? false) {
      return PaymentResult.success(
        transactionId: created.gatewayIntentId ?? 'pending',
        gatewayName: id,
      );
    }
    if (passed == false) {
      return const PaymentResult.failure(error: CardDeclinedError());
    }
    return const PaymentResult.canceled();
  }

  @override
  Future<PaymentResult> refund({
    required String transactionId,
    int? amountMinorUnits,
  }) async {
    final ok = await backend.refund(
      transactionId: transactionId,
      gatewayId: id,
      amountMinorUnits: amountMinorUnits,
    );
    if (!ok) {
      return PaymentResult.failure(
        error: GatewayUnavailableError(gateway: id),
      );
    }
    return PaymentResult.success(
      transactionId: transactionId,
      gatewayName: id,
    );
  }

  @override
  Future<PaymentStatus> getStatus({required String transactionId}) {
    return backend.getStatus(transactionId: transactionId, gatewayId: id);
  }
}
