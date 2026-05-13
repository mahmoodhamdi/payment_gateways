import 'package:flutter_test/flutter_test.dart';
import 'package:payment_gateways/payment_gateways.dart';

void main() {
  group('PaymentMethod', () {
    test('card method round-trips JSON', () {
      const m = PaymentMethod.card(brandHint: CardBrand.visa);
      final json = m.toJson();
      expect(json['kind'], 'card');
      expect(json['brand_hint'], 'visa');
      final decoded = PaymentMethod.fromJson(json);
      expect(decoded, m);
    });

    test('wallet method round-trips JSON', () {
      const m = PaymentMethod.wallet(type: WalletType.vodafoneCash);
      final json = m.toJson();
      expect(json['kind'], 'wallet');
      expect(json['wallet_type'], 'vodafoneCash');
      final decoded = PaymentMethod.fromJson(json);
      expect(decoded, m);
    });

    test('cash method round-trips JSON', () {
      const m = PaymentMethod.cash(type: CashType.fawryOutlet);
      final json = m.toJson();
      expect(json['kind'], 'cash');
      final decoded = PaymentMethod.fromJson(json);
      expect(decoded, m);
    });

    test('bank transfer method round-trips JSON', () {
      const m = PaymentMethod.bankTransfer(bank: 'NBE');
      final json = m.toJson();
      expect(json['kind'], 'bank_transfer');
      expect(json['bank'], 'NBE');
      final decoded = PaymentMethod.fromJson(json);
      expect(decoded, m);
    });

    test('fromJson throws on unknown kind', () {
      expect(
        () => PaymentMethod.fromJson({'kind': 'crypto'}),
        throwsA(isA<FormatException>()),
      );
    });

    test('exhaustive pattern matching works (Dart 3 sealed types)', () {
      String describe(PaymentMethod m) => switch (m) {
            CardPaymentMethod() => 'card',
            WalletPaymentMethod() => 'wallet',
            CashPaymentMethod() => 'cash',
            BankTransferMethod() => 'bank',
          };

      expect(describe(const PaymentMethod.card()), 'card');
      expect(
        describe(const PaymentMethod.wallet(type: WalletType.applePay)),
        'wallet',
      );
      expect(
        describe(const PaymentMethod.cash(type: CashType.fawryOutlet)),
        'cash',
      );
      expect(describe(const PaymentMethod.bankTransfer()), 'bank');
    });
  });
}
