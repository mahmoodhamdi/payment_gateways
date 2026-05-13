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
import 'package:payment_gateways/src/payment_gateways_facade.dart';
import 'package:payment_gateways/src/ui/three_ds_webview.dart';
import 'package:payment_gateways/src/utils/logger.dart';

/// PayPal adapter — global wallet & card.
///
/// Backend creates a PayPal order, returns the approval URL via
/// `clientSecret`. The adapter opens the URL in WebView, watches for the
/// merchant's success / failure redirects. After approval, the backend
/// captures the order server-side.
class PayPalGateway implements PaymentGateway {
  PayPalGateway({
    required this.config,
    required this.backend,
    required this.logger,
  });

  factory PayPalGateway.build(
    Object config,
    BackendClient backend,
    PaymentLogger logger,
  ) {
    if (config is! PayPalConfig) {
      throw ConfigError(
        details: 'Expected PayPalConfig but got ${config.runtimeType}',
      );
    }
    return PayPalGateway(config: config, backend: backend, logger: logger);
  }

  static const GatewayBuilder builder = GatewayBuilder(
    gatewayId: 'paypal',
    build: PayPalGateway.build,
  );

  static const String successUrlPrefix =
      'https://payment-gateways.local/paypal/success';
  static const String failureUrlPrefix =
      'https://payment-gateways.local/paypal/failure';

  final PayPalConfig config;
  final BackendClient backend;
  final PaymentLogger logger;

  @override
  String get id => 'paypal';

  @override
  GatewayMetadata get metadata => GatewayMetadata(
        id: 'paypal',
        displayName: 'PayPal',
        supportedCurrencies: {
          Currency.usd,
          Currency.eur,
          Currency.gbp,
        },
        supportedRegions: const {},
        supportsWallets: true,
        supportsSubscriptionsNatively: true,
      );

  @override
  bool supports(PaymentMethod method) => switch (method) {
        CardPaymentMethod() => true,
        WalletPaymentMethod(:final type) => type == WalletType.payPalWallet,
        _ => false,
      };

  @override
  Future<PaymentResult> initiate({
    required PaymentIntent intent,
    required PaymentMethod method,
    required BuildContext context,
  }) async {
    final created = await backend.createIntent(intent: intent, gatewayId: id);
    final approvalUrl = created.clientSecret;
    if (approvalUrl == null) {
      return const PaymentResult.failure(
        error: ConfigError(
          details: 'Backend did not return PayPal approval URL.',
        ),
      );
    }
    if (!context.mounted) return const PaymentResult.canceled();
    final passed = await ThreeDSWebView.show(
      context,
      actionUrl: Uri.parse(approvalUrl),
      successUrlPrefix: successUrlPrefix,
      failureUrlPrefix: failureUrlPrefix,
      title: 'PayPal Checkout',
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
