import 'package:meta/meta.dart';

/// ISO 3166-1 alpha-2 country code (`EG`, `SA`, `AE`, `US`, `GB`, `NG`, ...).
///
/// Stored as an opaque uppercase string for routing decisions and gateway
/// availability checks. Use [Region.parse] to validate input.
@immutable
class Region {
  const Region._(this.code);

  /// Parses an ISO 3166-1 alpha-2 country code. Two-letter, uppercased.
  /// Throws [FormatException] if the input is not exactly two ASCII letters.
  factory Region.parse(String code) {
    final upper = code.toUpperCase();
    if (upper.length != 2 ||
        !upper.codeUnits.every((u) => u >= 0x41 && u <= 0x5A)) {
      throw FormatException(
        'Region must be a two-letter ISO 3166-1 alpha-2 code',
        code,
      );
    }
    return Region._(upper);
  }

  final String code;

  // Convenience constants for hot paths. The full ISO list is intentionally
  // not enumerated — `Region.parse(...)` covers any code on demand.
  static const Region eg = Region._('EG');
  static const Region sa = Region._('SA');
  static const Region ae = Region._('AE');
  static const Region kw = Region._('KW');
  static const Region qa = Region._('QA');
  static const Region bh = Region._('BH');
  static const Region om = Region._('OM');
  static const Region us = Region._('US');
  static const Region gb = Region._('GB');
  static const Region ca = Region._('CA');
  static const Region au = Region._('AU');
  static const Region ng = Region._('NG');

  @override
  bool operator ==(Object other) => other is Region && other.code == code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => code;
}
