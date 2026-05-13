import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payment_gateways/payment_gateways.dart';

void main() {
  group('PaymentMethodSelector', () {
    testWidgets('renders one tile per available method', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentMethodSelector(
              available: const [
                PaymentMethod.card(),
                PaymentMethod.wallet(type: WalletType.applePay),
                PaymentMethod.cash(type: CashType.fawryOutlet),
              ],
              value: null,
              onChanged: (_) {},
            ),
          ),
        ),
      );
      expect(find.text('Card'), findsOneWidget);
      expect(find.text('Apple Pay'), findsOneWidget);
      expect(find.text('Fawry (cash at outlet)'), findsOneWidget);
    });

    testWidgets('emits onChanged when a tile is tapped', (tester) async {
      PaymentMethod? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentMethodSelector(
              available: const [
                PaymentMethod.card(),
                PaymentMethod.wallet(type: WalletType.googlePay),
              ],
              value: null,
              onChanged: (m) => selected = m,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Google Pay'));
      await tester.pump();
      expect(selected, isA<WalletPaymentMethod>());
    });
  });

  group('OrderSummary', () {
    testWidgets('renders subtotal and total', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OrderSummary(
              items: [
                OrderLineItem(name: 'Hoodie', amountMinorUnits: 4999),
                OrderLineItem(
                  name: 'Sticker pack',
                  amountMinorUnits: 500,
                  quantity: 2,
                ),
              ],
              total: Money(
                amountMinorUnits: 5999,
                currency: Currency.usd,
              ),
            ),
          ),
        ),
      );
      expect(find.text('Hoodie'), findsOneWidget);
      expect(find.text('Sticker pack × 2'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
      expect(find.text('Subtotal'), findsOneWidget);
    });
  });
}
