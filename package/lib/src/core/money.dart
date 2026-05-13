import 'package:meta/meta.dart';
import 'package:payment_gateways/src/core/currency.dart';

/// An exact monetary value, stored as an integer count of [currency]'s minor
/// units. Floating-point representations of money are deliberately avoided.
@immutable
class Money {
  /// Build a Money directly from minor units (cents, piastres, fils, ...).
  const Money({required this.amountMinorUnits, required this.currency});

  /// Build a Money from a decimal major-unit string (`"12.50"`, `"100"`).
  /// Useful when reading prices from product catalogs.
  factory Money.fromMajor(String amount, Currency currency) {
    final parsed = double.tryParse(amount);
    if (parsed == null) {
      throw FormatException('Money amount must be a decimal number', amount);
    }
    return Money(
      amountMinorUnits: currency.toMinorUnits(parsed),
      currency: currency,
    );
  }

  final int amountMinorUnits;
  final Currency currency;

  /// Major-unit double representation. Use for display only — never for
  /// arithmetic.
  double get amountMajor => currency.toMajorUnits(amountMinorUnits);

  Money operator +(Money other) {
    _requireSameCurrency(other);
    return Money(
      amountMinorUnits: amountMinorUnits + other.amountMinorUnits,
      currency: currency,
    );
  }

  Money operator -(Money other) {
    _requireSameCurrency(other);
    return Money(
      amountMinorUnits: amountMinorUnits - other.amountMinorUnits,
      currency: currency,
    );
  }

  Money operator *(num factor) => Money(
        amountMinorUnits: (amountMinorUnits * factor).round(),
        currency: currency,
      );

  bool get isPositive => amountMinorUnits > 0;
  bool get isZero => amountMinorUnits == 0;
  bool get isNegative => amountMinorUnits < 0;

  void _requireSameCurrency(Money other) {
    if (other.currency != currency) {
      throw ArgumentError(
        'Cannot combine Money values of different currencies '
        '($currency vs ${other.currency})',
      );
    }
  }

  Map<String, dynamic> toJson() => {
        'amount_minor_units': amountMinorUnits,
        'currency': currency.code,
      };

  factory Money.fromJson(Map<String, dynamic> json) {
    return Money(
      amountMinorUnits: json['amount_minor_units'] as int,
      currency: Currency.parse(json['currency'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Money &&
      other.amountMinorUnits == amountMinorUnits &&
      other.currency == currency;

  @override
  int get hashCode => Object.hash(amountMinorUnits, currency);

  @override
  String toString() => '$amountMinorUnits ${currency.code} (minor)';
}
