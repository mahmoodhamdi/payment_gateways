import 'dart:ui' show Locale;

import 'package:meta/meta.dart';
import 'package:payment_gateways/src/core/environment.dart';
import 'package:payment_gateways/src/core/gateway_config.dart';
import 'package:payment_gateways/src/core/payment_router.dart';

/// Top-level configuration for the SDK.
///
/// Keys here are public/publishable only. Secret keys belong server-side
/// (the backend_companion in this repo).
@immutable
class PaymentConfig {
  const PaymentConfig({
    required this.environment,
    required this.gateways,
    required this.backendBaseUrl,
    this.routing = const RoutingRules.byCountry(),
    this.locale = const Locale('en', 'US'),
    this.networkTimeout = const Duration(seconds: 30),
  });

  /// `Environment.test` or `Environment.production`.
  final Environment environment;

  /// Map from gateway id (`"stripe"`, `"paymob"`, …) to its config.
  /// Use `GatewayConfig.stripe(...)` etc.
  final Map<String, GatewayConfig> gateways;

  /// Routing rules used when the caller does not pin a specific gateway.
  final RoutingRules routing;

  /// Base URL of your backend companion. The SDK calls this server for:
  ///   - Creating a payment intent (so secret keys stay server-side).
  ///   - Polling payment status.
  ///   - Initiating refunds.
  final Uri backendBaseUrl;

  /// Locale for UI strings.
  final Locale locale;

  /// Per-request network timeout.
  final Duration networkTimeout;

  /// Validates each configured gateway. Throws on the first invalid one.
  void validate() {
    if (gateways.isEmpty) {
      throw ArgumentError('At least one gateway must be configured.');
    }
    for (final entry in gateways.entries) {
      if (entry.key != entry.value.gatewayId) {
        throw ArgumentError(
          'Gateway map key "${entry.key}" does not match '
          'config.gatewayId "${entry.value.gatewayId}".',
        );
      }
      entry.value.validate();
    }
    if (!backendBaseUrl.hasScheme || backendBaseUrl.scheme != 'https') {
      if (environment == Environment.production) {
        throw ArgumentError(
          'backendBaseUrl must use HTTPS in production '
          '(got: $backendBaseUrl).',
        );
      }
    }
  }

  /// Returns whether the given gateway id is configured.
  bool hasGateway(String id) => gateways.containsKey(id);
}
