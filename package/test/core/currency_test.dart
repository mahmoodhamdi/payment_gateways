import 'package:flutter_test/flutter_test.dart';
import 'package:payment_gateways/payment_gateways.dart';

void main() {
  group('Currency', () {
    test('known 2-exponent currencies', () {
      expect(Currency.usd.minorUnitExponent, 2);
      expect(Currency.egp.minorUnitExponent, 2);
      expect(Currency.aed.minorUnitExponent, 2);
    });

    test('known 3-exponent (Gulf) currencies', () {
      expect(Currency.kwd.minorUnitExponent, 3);
      expect(Currency.bhd.minorUnitExponent, 3);
      expect(Currency.omr.minorUnitExponent, 3);
    });

    test('known 0-exponent currencies', () {
      expect(Currency.jpy.minorUnitExponent, 0);
    });

    test('parse uppercases input', () {
      expect(Currency.parse('usd').code, 'USD');
    });

    test('parse rejects non-letter or wrong-length input', () {
      expect(() => Currency.parse('us'), throwsA(isA<FormatException>()));
      expect(() => Currency.parse('us1'), throwsA(isA<FormatException>()));
      expect(() => Currency.parse('USDA'), throwsA(isA<FormatException>()));
    });

    test('parse defaults unknown codes to 2-exponent', () {
      final c = Currency.parse('ZZZ');
      expect(c.minorUnitExponent, 2);
    });

    test('toMinorUnits rounds half-to-even', () {
      expect(Currency.usd.toMinorUnits(0.005), 1); // round up at .5
      expect(Currency.usd.toMinorUnits(12.5), 1250);
    });
  });
}
