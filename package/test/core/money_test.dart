import 'package:flutter_test/flutter_test.dart';
import 'package:payment_gateways/payment_gateways.dart';

void main() {
  group('Money', () {
    test('round-trips JSON', () {
      const m = Money(amountMinorUnits: 4999, currency: Currency.usd);
      final json = m.toJson();
      expect(json['amount_minor_units'], 4999);
      expect(json['currency'], 'USD');
      final decoded = Money.fromJson(json);
      expect(decoded, m);
    });

    test('fromMajor parses major-unit string for 2-exponent currency', () {
      final m = Money.fromMajor('49.99', Currency.usd);
      expect(m.amountMinorUnits, 4999);
    });

    test('fromMajor parses major-unit string for 3-exponent currency (KWD)',
        () {
      final m = Money.fromMajor('12.345', Currency.kwd);
      expect(m.amountMinorUnits, 12345);
    });

    test('fromMajor parses major-unit string for 0-exponent currency (JPY)',
        () {
      final m = Money.fromMajor('500', Currency.jpy);
      expect(m.amountMinorUnits, 500);
    });

    test('fromMajor throws on non-numeric input', () {
      expect(
        () => Money.fromMajor('not-a-number', Currency.usd),
        throwsA(isA<FormatException>()),
      );
    });

    test('arithmetic across same currency works', () {
      const a = Money(amountMinorUnits: 1000, currency: Currency.usd);
      const b = Money(amountMinorUnits: 250, currency: Currency.usd);
      expect((a + b).amountMinorUnits, 1250);
      expect((a - b).amountMinorUnits, 750);
      expect((a * 1.5).amountMinorUnits, 1500);
    });

    test('arithmetic across different currencies throws', () {
      const a = Money(amountMinorUnits: 1000, currency: Currency.usd);
      const b = Money(amountMinorUnits: 1000, currency: Currency.egp);
      expect(() => a + b, throwsArgumentError);
      expect(() => a - b, throwsArgumentError);
    });

    test('amountMajor reflects exponent', () {
      const m = Money(amountMinorUnits: 4999, currency: Currency.usd);
      expect(m.amountMajor, closeTo(49.99, 1e-9));
    });

    test('sign predicates', () {
      expect(
        const Money(amountMinorUnits: 1, currency: Currency.usd).isPositive,
        true,
      );
      expect(
        const Money(amountMinorUnits: 0, currency: Currency.usd).isZero,
        true,
      );
      expect(
        const Money(amountMinorUnits: -1, currency: Currency.usd).isNegative,
        true,
      );
    });
  });
}
