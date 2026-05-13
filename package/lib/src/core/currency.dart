import 'package:meta/meta.dart';

/// ISO 4217 currency identifier with knowledge of its minor-unit exponent.
///
/// Most currencies use 2 minor units per major unit (USD: cents).
/// A handful use 0 (JPY, KRW) or 3 (KWD, BHD, OMR — Gulf dinars).
@immutable
class Currency {
  const Currency._(this.code, this.minorUnitExponent);

  /// Parses an ISO 4217 three-letter currency code (`USD`, `EGP`, `SAR`, ...).
  /// Uses the registered minor-unit exponent for known currencies, otherwise
  /// defaults to 2.
  factory Currency.parse(String code) {
    final upper = code.toUpperCase();
    if (upper.length != 3 ||
        !upper.codeUnits.every((u) => u >= 0x41 && u <= 0x5A)) {
      throw FormatException(
        'Currency must be a three-letter ISO 4217 code',
        code,
      );
    }
    return Currency._(upper, _minorUnitExponentFor(upper));
  }

  final String code;
  final int minorUnitExponent;

  // High-traffic constants.
  static const Currency usd = Currency._('USD', 2);
  static const Currency eur = Currency._('EUR', 2);
  static const Currency gbp = Currency._('GBP', 2);
  static const Currency egp = Currency._('EGP', 2);
  static const Currency sar = Currency._('SAR', 2);
  static const Currency aed = Currency._('AED', 2);
  static const Currency kwd = Currency._('KWD', 3);
  static const Currency bhd = Currency._('BHD', 3);
  static const Currency omr = Currency._('OMR', 3);
  static const Currency qar = Currency._('QAR', 2);
  static const Currency ngn = Currency._('NGN', 2);
  static const Currency jpy = Currency._('JPY', 0);

  static int _minorUnitExponentFor(String code) {
    return switch (code) {
      'KWD' || 'BHD' || 'OMR' || 'JOD' || 'TND' => 3,
      'JPY' || 'KRW' || 'CLP' || 'PYG' || 'VND' || 'XOF' || 'XAF' => 0,
      _ => 2,
    };
  }

  /// Convert a major-unit decimal amount (`12.50`) to minor units (`1250`).
  /// Rounds half-to-even at the appropriate precision.
  int toMinorUnits(double major) {
    final factor = _pow10(minorUnitExponent);
    return (major * factor).round();
  }

  /// Inverse of [toMinorUnits].
  double toMajorUnits(int minor) {
    final factor = _pow10(minorUnitExponent);
    return minor / factor;
  }

  static int _pow10(int n) {
    var result = 1;
    for (var i = 0; i < n; i++) {
      result *= 10;
    }
    return result;
  }

  @override
  bool operator ==(Object other) => other is Currency && other.code == code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => code;
}
