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

/// Paymob adapter (Egypt).
///
/// Flow per Paymob "Accept" docs:
///
/// 1. Backend creates an order, then a payment_key, and assembles the
///    iframe URL: `https://accept.paymob.com/api/acceptance/iframes/<id>?
///    payment_token=<key>`. Returned via `/api/checkout`.
/// 2. The adapter opens that URL in a WebView and watches for a redirect
///    to the merchant's success / failure URLs (matching the constants
///    below).
/// 3. The actual settlement notification arrives via Paymob's HMAC-signed
///    webhook to `/webhooks/paymob` on the backend.
class PaymobGateway implements PaymentGateway {
  PaymobGateway({
    required this.config,
    required this.backend,
    required this.logger,
  });

  factory PaymobGateway.build(
    Object config,
    BackendClient backend,
    PaymentLogger logger,
  ) {
    if (config is! PaymobConfig) {
      throw ConfigError(
        details: 'Expected PaymobConfig but got ${config.runtimeType}',
      );
    }
    return PaymobGateway(config: config, backend: backend, logger: logger);
  }

  static const GatewayBuilder builder = GatewayBuilder(
    gatewayId: 'paymob',
    build: PaymobGateway.build,
  );

  /// URL prefix the backend redirects to on success in the Paymob iframe.
  static const String successUrlPrefix =
      'https://payment-gateways.local/paymob/success';

  /// URL prefix the backend redirects to on failure in the Paymob iframe.
  static const String failureUrlPrefix =
      'https://payment-gateways.local/paymob/failure';

  final PaymobConfig config;
  final BackendClient backend;
  final PaymentLogger logger;

  @override
  String get id => 'paymob';

  @override
  GatewayMetadata get metadata => GatewayMetadata(
        id: 'paymob',
        displayName: 'Paymob',
        supportedCurrencies: {Currency.egp},
        supportedRegions: {Region.eg},
        supportsWallets: true,
        // Paymob supports recurring via the merchant's own scheduling layer
        // — not natively.
      );

  @override
  bool supports(PaymentMethod method) => switch (method) {
        CardPaymentMethod() => true,
        WalletPaymentMethod(:final type) => switch (type) {
            WalletType.vodafoneCash ||
            WalletType.orangeCash ||
            WalletType.etisalatCash =>
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
          gatewayMessage: 'Paymob does not support method ${method.kind}',
        ),
      );
    }

    final created = await backend.createIntent(intent: intent, gatewayId: id);
    // Backend returns the iframe URL in clientSecret for Paymob (re-purposing
    // the field; documented behavior).
    final iframeUrlStr = created.clientSecret;
    if (iframeUrlStr == null) {
      return const PaymentResult.failure(
        error: ConfigError(
          details:
              'Backend did not return Paymob iframe URL. Check your '
              '/api/checkout endpoint and the integration_ids you set in '
              'PaymobConfig.',
        ),
      );
    }

    if (!context.mounted) return const PaymentResult.canceled();

    final passed = await ThreeDSWebView.show(
      context,
      actionUrl: Uri.parse(iframeUrlStr),
      successUrlPrefix: successUrlPrefix,
      failureUrlPrefix: failureUrlPrefix,
      title: 'Paymob — secure checkout',
    );

    if (passed ?? false) {
      return PaymentResult.success(
        transactionId: created.gatewayIntentId ?? 'pending',
        gatewayName: id,
      );
    }
    if (passed == false) {
      return const PaymentResult.failure(
        error: CardDeclinedError(reason: 'Paymob declined the transaction'),
      );
    }
    return const PaymentResult.canceled();
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
            gatewayMessage: 'Refund rejected by Paymob.',
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
