import 'package:flutter/widgets.dart';
import 'package:payment_gateways/src/backend/backend_client.dart';
import 'package:payment_gateways/src/core/currency.dart';
import 'package:payment_gateways/src/core/payment_config.dart';
import 'package:payment_gateways/src/core/payment_error.dart';
import 'package:payment_gateways/src/core/payment_gateway.dart';
import 'package:payment_gateways/src/core/payment_intent.dart';
import 'package:payment_gateways/src/core/payment_method.dart';
import 'package:payment_gateways/src/core/payment_result.dart';
import 'package:payment_gateways/src/core/payment_router.dart';
import 'package:payment_gateways/src/core/region.dart';
import 'package:payment_gateways/src/utils/logger.dart';

/// Top-level entry point for the SDK.
///
/// Typical usage:
///
/// ```dart
/// final gateways = PaymentGateways(
///   config: PaymentConfig(...),
///   gatewayBuilders: [
///     (cfg, backend) => StripeGateway(cfg, backend),
///     (cfg, backend) => PaymobGateway(cfg, backend),
///   ],
/// );
///
/// final result = await gateways.checkout(
///   intent: ..., method: ..., context: context,
/// );
/// ```
class PaymentGateways {
  PaymentGateways({
    required this.config,
    required List<GatewayBuilder> gatewayBuilders,
    PaymentLogger? logger,
    BackendClient? backendClient,
  })  : _logger = logger ?? PaymentLogger(),
        _backend =
            backendClient ?? BackendClient(config: config, logger: logger) {
    config.validate();
    final built = <PaymentGateway>[];
    for (final entry in config.gateways.entries) {
      final builder = gatewayBuilders.firstWhere(
        (b) => b.gatewayId == entry.key,
        orElse: () => throw ConfigError(
          details: 'No gatewayBuilder registered for "${entry.key}". '
              'Add the corresponding adapter to gatewayBuilders.',
        ),
      );
      built.add(builder.build(entry.value, _backend, _logger));
    }
    _router = PaymentRouter(rules: config.routing, gateways: built);
  }

  final PaymentConfig config;
  final PaymentLogger _logger;
  final BackendClient _backend;
  late final PaymentRouter _router;

  /// Run the checkout flow. The router picks a gateway unless [pinGatewayId]
  /// is supplied.
  Future<PaymentResult> checkout({
    required PaymentIntent intent,
    required PaymentMethod method,
    required BuildContext context,
    String? pinGatewayId,
  }) async {
    final country = intent.customer.billingAddress?.country;

    final PaymentGateway gateway;
    try {
      gateway = pinGatewayId != null
          ? _router.registered.firstWhere(
              (g) => g.id == pinGatewayId,
              orElse: () => throw GatewayUnavailableError(
                gateway: pinGatewayId,
                gatewayMessage:
                    'Pinned gateway "$pinGatewayId" not configured.',
              ),
            )
          : _router.select(
              method: method,
              currency: intent.currency,
              customerCountry: country,
            );
    } on PaymentError catch (e) {
      _logger.warn(
        'Router rejected request',
        data: {
          'method': method.kind,
          'currency': intent.currency.code,
          'country': country?.code,
          'code': e.code,
        },
      );
      return PaymentResult.failure(error: e);
    }

    _logger.info(
      'Routing to gateway',
      data: {
        'gateway': gateway.id,
        'method': method.kind,
        'currency': intent.currency.code,
      },
    );

    try {
      return await gateway.initiate(
        intent: intent.copyWith(gatewayName: gateway.id),
        method: method,
        context: context,
      );
    } on PaymentError catch (e) {
      return PaymentResult.failure(error: e);
    } catch (e, stack) {
      _logger.error(
        'Adapter threw an unhandled error',
        error: e,
        stackTrace: stack,
        data: {'gateway': gateway.id},
      );
      return PaymentResult.failure(
        error: UnknownError(cause: e),
      );
    }
  }

  /// Refund a transaction. Always goes via the backend (secret keys live
  /// there).
  Future<PaymentResult> refund({
    required String transactionId,
    required String gatewayId,
    int? amountMinorUnits,
  }) async {
    try {
      final ok = await _backend.refund(
        transactionId: transactionId,
        gatewayId: gatewayId,
        amountMinorUnits: amountMinorUnits,
      );
      if (!ok) {
        return PaymentResult.failure(
          error: GatewayUnavailableError(
            gateway: gatewayId,
            gatewayMessage: 'Refund rejected by gateway.',
          ),
        );
      }
      return PaymentResult.success(
        transactionId: transactionId,
        gatewayName: gatewayId,
      );
    } on PaymentError catch (e) {
      return PaymentResult.failure(error: e);
    }
  }

  /// Static reachability check used by UIs to enable/disable buttons.
  bool canAccept({
    required PaymentMethod method,
    required Currency currency,
    Region? customerCountry,
  }) {
    return config.routing.select(
          available: _router.registered,
          method: method,
          currency: currency,
          customerCountry: customerCountry,
        ) !=
        null;
  }

  /// Backend handle used by adapters; integrators normally don't need this.
  BackendClient get backend => _backend;
  PaymentRouter get router => _router;
}

/// Recipe used by [PaymentGateways] to instantiate adapters from a
/// per-gateway config.
class GatewayBuilder {
  const GatewayBuilder({
    required this.gatewayId,
    required this.build,
  });

  final String gatewayId;
  final PaymentGateway Function(
    Object config,
    BackendClient backend,
    PaymentLogger logger,
  ) build;
}
