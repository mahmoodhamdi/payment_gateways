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
import 'package:payment_gateways/src/utils/logger.dart';

/// Fawry adapter (Egypt cash-at-outlet flow).
///
/// Fawry is unique among the supported gateways: the customer does **not**
/// pay inside the app. The flow is:
///
/// 1. App calls `/api/checkout`. Backend creates a Fawry charge and gets
///    back a reference number (e.g. `1234567890`).
/// 2. Adapter returns [PaymentPendingAction] with that reference. The
///    caller's UI is expected to show the reference to the user, optionally
///    with instructions ("Visit any Fawry outlet, give them this number,
///    pay in cash").
/// 3. The customer pays cash at a Fawry outlet / ATM / online banking app.
///    Hours or days may pass.
/// 4. Fawry POSTs a webhook to `/webhooks/fawry` on the backend with the
///    final status. Your app polls `getStatus` or subscribes to backend
///    updates.
class FawryGateway implements PaymentGateway {
  FawryGateway({
    required this.config,
    required this.backend,
    required this.logger,
  });

  factory FawryGateway.build(
    Object config,
    BackendClient backend,
    PaymentLogger logger,
  ) {
    if (config is! FawryConfig) {
      throw ConfigError(
        details: 'Expected FawryConfig but got ${config.runtimeType}',
      );
    }
    return FawryGateway(config: config, backend: backend, logger: logger);
  }

  static const GatewayBuilder builder = GatewayBuilder(
    gatewayId: 'fawry',
    build: FawryGateway.build,
  );

  final FawryConfig config;
  final BackendClient backend;
  final PaymentLogger logger;

  @override
  String get id => 'fawry';

  @override
  GatewayMetadata get metadata => GatewayMetadata(
        id: 'fawry',
        displayName: 'Fawry',
        supportedCurrencies: {Currency.egp},
        supportedRegions: {Region.eg},
        supportsCards: false,
        supportsCash: true,
      );

  @override
  bool supports(PaymentMethod method) => switch (method) {
        CashPaymentMethod(:final type) => switch (type) {
            CashType.fawryOutlet || CashType.fawryAtm => true,
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
          gatewayMessage: 'Fawry only supports cash methods.',
        ),
      );
    }

    final created = await backend.createIntent(intent: intent, gatewayId: id);
    // For Fawry, the backend sets clientSecret to the reference number.
    final reference = created.clientSecret;
    if (reference == null) {
      return const PaymentResult.failure(
        error: ConfigError(
          details:
              'Backend did not return Fawry reference number. Check your '
              '/api/checkout endpoint.',
        ),
      );
    }

    final actionUrl = Uri(
      scheme: 'payment-gateways',
      host: 'fawry',
      pathSegments: ['cash', reference],
    );

    return PaymentResult.pendingAction(
      actionUrl: actionUrl,
      transactionId: created.gatewayIntentId,
      type: PendingActionType.cashAtOutlet,
      reference: reference,
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
            gatewayMessage: 'Fawry refund rejected.',
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
