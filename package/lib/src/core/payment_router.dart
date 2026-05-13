import 'package:payment_gateways/src/core/currency.dart';
import 'package:payment_gateways/src/core/payment_error.dart';
import 'package:payment_gateways/src/core/payment_gateway.dart';
import 'package:payment_gateways/src/core/payment_method.dart';
import 'package:payment_gateways/src/core/region.dart';

/// How the router picks a gateway when the caller does not pin one
/// explicitly.
abstract class RoutingRules {
  /// Pick by best-fit across customer country, method, and currency.
  const factory RoutingRules.byCountry() = _ByCountryRouting;

  /// Pin a gateway regardless of country / method (used for tests).
  const factory RoutingRules.fixed(String gatewayId) = _FixedRouting;

  /// User-supplied policy.
  const factory RoutingRules.custom(GatewaySelector selector) = _CustomRouting;

  const RoutingRules._();

  /// Choose a gateway from [available]; return `null` if no gateway is a fit
  /// (caller should surface a [GatewayUnavailableError]).
  PaymentGateway? select({
    required List<PaymentGateway> available,
    required PaymentMethod method,
    required Currency currency,
    required Region? customerCountry,
  });
}

typedef GatewaySelector = PaymentGateway? Function({
  required List<PaymentGateway> available,
  required PaymentMethod method,
  required Currency currency,
  required Region? customerCountry,
});

class _ByCountryRouting extends RoutingRules {
  const _ByCountryRouting() : super._();

  @override
  PaymentGateway? select({
    required List<PaymentGateway> available,
    required PaymentMethod method,
    required Currency currency,
    required Region? customerCountry,
  }) {
    final filtered = available.where((g) {
      if (!g.supports(method)) return false;
      if (!g.metadata.supportsCurrency(currency)) return false;
      if (customerCountry != null &&
          g.metadata.supportedRegions.isNotEmpty &&
          !g.metadata.supportsRegion(customerCountry)) {
        return false;
      }
      return true;
    }).toList();

    if (filtered.isEmpty) return null;

    // Country preference order: MENA gateways first when customer is in MENA
    // and they exist; otherwise alphabetical for determinism.
    if (customerCountry != null && _menaCodes.contains(customerCountry.code)) {
      filtered.sort(
        (a, b) => _menaRanking(b.id).compareTo(_menaRanking(a.id)),
      );
    } else {
      filtered.sort((a, b) => a.id.compareTo(b.id));
    }

    return filtered.first;
  }

  // Use ISO codes in a const set (string equality is primitive).
  static const _menaCodes = {'EG', 'SA', 'AE', 'KW', 'QA', 'BH', 'OM'};

  static int _menaRanking(String id) {
    return switch (id) {
      'paymob' => 100,
      'paytabs' => 90,
      'fawry' => 80,
      'stripe' => 50,
      'paypal' => 40,
      _ => 0,
    };
  }
}

class _FixedRouting extends RoutingRules {
  const _FixedRouting(this.gatewayId) : super._();

  final String gatewayId;

  @override
  PaymentGateway? select({
    required List<PaymentGateway> available,
    required PaymentMethod method,
    required Currency currency,
    required Region? customerCountry,
  }) {
    for (final g in available) {
      if (g.id == gatewayId) return g;
    }
    return null;
  }
}

class _CustomRouting extends RoutingRules {
  const _CustomRouting(this.selector) : super._();

  final GatewaySelector selector;

  @override
  PaymentGateway? select({
    required List<PaymentGateway> available,
    required PaymentMethod method,
    required Currency currency,
    required Region? customerCountry,
  }) {
    return selector(
      available: available,
      method: method,
      currency: currency,
      customerCountry: customerCountry,
    );
  }
}

/// Orchestrates gateway selection using [RoutingRules].
class PaymentRouter {
  PaymentRouter({
    required this.rules,
    required List<PaymentGateway> gateways,
  }) : _gateways = List.unmodifiable(gateways);

  final RoutingRules rules;
  final List<PaymentGateway> _gateways;

  List<PaymentGateway> get registered => _gateways;

  /// Returns the chosen gateway, or throws [GatewayUnavailableError] when no
  /// available gateway fits the request.
  PaymentGateway select({
    required PaymentMethod method,
    required Currency currency,
    required Region? customerCountry,
  }) {
    final chosen = rules.select(
      available: _gateways,
      method: method,
      currency: currency,
      customerCountry: customerCountry,
    );
    if (chosen == null) {
      throw GatewayUnavailableError(
        gateway: 'router',
        gatewayMessage:
            'No configured gateway supports $method / $currency / '
            '${customerCountry ?? 'any country'}.',
      );
    }
    return chosen;
  }
}
