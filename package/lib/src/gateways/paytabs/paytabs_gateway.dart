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

/// PayTabs adapter (Saudi Arabia / Gulf).
///
/// Like Paymob, PayTabs uses a hosted "PayPage" iframe. The backend creates
/// the PayPage and returns the URL via clientSecret; the adapter opens it
/// in a WebView and watches for the merchant's success / failure redirect.
class PayTabsGateway implements PaymentGateway {
  PayTabsGateway({
    required this.config,
    required this.backend,
    required this.logger,
  });

  factory PayTabsGateway.build(
    Object config,
    BackendClient backend,
    PaymentLogger logger,
  ) {
    if (config is! PayTabsConfig) {
      throw ConfigError(
        details: 'Expected PayTabsConfig but got ${config.runtimeType}',
      );
    }
    return PayTabsGateway(config: config, backend: backend, logger: logger);
  }

  static const GatewayBuilder builder = GatewayBuilder(
    gatewayId: 'paytabs',
    build: PayTabsGateway.build,
  );

  static const String successUrlPrefix =
      'https://payment-gateways.local/paytabs/success';
  static const String failureUrlPrefix =
      'https://payment-gateways.local/paytabs/failure';

  final PayTabsConfig config;
  final BackendClient backend;
  final PaymentLogger logger;

  @override
  String get id => 'paytabs';

  @override
  GatewayMetadata get metadata => GatewayMetadata(
        id: 'paytabs',
        displayName: 'PayTabs',
        supportedCurrencies: {
          Currency.sar,
          Currency.aed,
          Currency.kwd,
          Currency.bhd,
          Currency.qar,
          Currency.omr,
          Currency.egp,
        },
        supportedRegions: {
          Region.sa,
          Region.ae,
          Region.kw,
          Region.bh,
          Region.qa,
          Region.om,
          Region.eg,
        },
        supportsWallets: true,
      );

  @override
  bool supports(PaymentMethod method) => switch (method) {
        CardPaymentMethod() => true,
        WalletPaymentMethod(:final type) =>
          type == WalletType.applePay || type == WalletType.mada,
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
          gatewayMessage: 'PayTabs does not support method ${method.kind}',
        ),
      );
    }
    final created = await backend.createIntent(intent: intent, gatewayId: id);
    final payPageUrl = created.clientSecret;
    if (payPageUrl == null) {
      return const PaymentResult.failure(
        error: ConfigError(
          details: 'Backend did not return PayTabs PayPage URL.',
        ),
      );
    }
    if (!context.mounted) return const PaymentResult.canceled();
    final passed = await ThreeDSWebView.show(
      context,
      actionUrl: Uri.parse(payPageUrl),
      successUrlPrefix: successUrlPrefix,
      failureUrlPrefix: failureUrlPrefix,
      title: 'PayTabs — secure checkout',
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
