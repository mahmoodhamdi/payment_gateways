import 'package:meta/meta.dart';
import 'package:payment_gateways/src/core/currency.dart';
import 'package:payment_gateways/src/core/region.dart';

/// Static descriptor of a payment gateway: which currencies, regions, methods
/// it supports, used for routing and UI presentation.
@immutable
class GatewayMetadata {
  const GatewayMetadata({
    required this.id,
    required this.displayName,
    required this.supportedCurrencies,
    required this.supportedRegions,
    this.supportsCards = true,
    this.supportsWallets = false,
    this.supportsCash = false,
    this.supportsBankTransfer = false,
    this.supportsSubscriptionsNatively = false,
    this.supportsRefunds = true,
    this.tagline,
  });

  /// Stable id used internally (`"stripe"`, `"paymob"`, ...).
  final String id;

  /// Human-readable name.
  final String displayName;

  final Set<Currency> supportedCurrencies;
  final Set<Region> supportedRegions;

  final bool supportsCards;
  final bool supportsWallets;
  final bool supportsCash;
  final bool supportsBankTransfer;
  final bool supportsSubscriptionsNatively;
  final bool supportsRefunds;

  final String? tagline;

  bool supportsCurrency(Currency c) => supportedCurrencies.contains(c);
  bool supportsRegion(Region r) => supportedRegions.contains(r);
}
