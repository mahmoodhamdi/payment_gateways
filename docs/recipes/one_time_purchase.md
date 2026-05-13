# Recipe: One-time purchase

A standard "user buys a thing" checkout. The most common flow.

```dart
import 'package:flutter/material.dart';
import 'package:payment_gateways/payment_gateways.dart';

class BuyButton extends StatelessWidget {
  const BuyButton({super.key, required this.gateways, required this.product});

  final PaymentGateways gateways;
  final Product product;

  Future<void> _buy(BuildContext context) async {
    final intent = PaymentIntent(
      id: 'order_${DateTime.now().millisecondsSinceEpoch}',
      amountMinorUnits: product.priceMinorUnits,
      currency: product.currency,
      customer: Customer(
        id: currentUser.id,
        email: currentUser.email,
        phone: currentUser.phone,
        billingAddress: Address(country: Region.parse(currentUser.country)),
      ),
      metadata: OrderMetadata(
        description: product.name,
        items: [
          OrderLineItem(
            name: product.name,
            amountMinorUnits: product.priceMinorUnits,
            sku: product.sku,
          ),
        ],
      ),
    );

    final result = await gateways.checkout(
      intent: intent,
      method: const PaymentMethod.card(),
      context: context,
    );

    if (!context.mounted) return;
    await PaymentResultDialog.show(context, result: result);

    switch (result) {
      case PaymentSuccess(:final transactionId):
        await OrderService.confirm(intent.id, transactionId);
      case PaymentPendingAction(:final reference):
        await OrderService.markAwaitingCash(intent.id, reference);
      case PaymentFailure() || PaymentCanceled():
        // nothing to do — user can retry
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _buy(context),
      child: Text('Buy ${product.name}'),
    );
  }
}
```

## What's happening

1. Build an immutable `PaymentIntent` carrying the order, amount, currency, customer, and optional metadata.
2. Call `gateways.checkout(...)`. The router picks the best gateway based on the customer's country and the available methods.
3. The chosen adapter shows its UI (card sheet for Stripe; iframe WebView for Paymob/PayTabs; reference number for Fawry).
4. The `PaymentResult` is one of four sealed variants. Switch on them.
5. Confirm the order on `PaymentSuccess`; mark it pending on `PaymentPendingAction` (Fawry); leave it alone on `PaymentFailure` / `PaymentCanceled`.

## Pin the gateway

Skip the router by passing `pinGatewayId`:

```dart
final result = await gateways.checkout(
  intent: intent,
  method: const PaymentMethod.card(),
  context: context,
  pinGatewayId: 'paymob', // always use Paymob, even for non-EG customers
);
```

## Show the order summary before paying

```dart
CheckoutForm(
  total: Money(
    amountMinorUnits: product.priceMinorUnits,
    currency: Currency.parse(product.currency),
  ),
  availableMethods: const [
    PaymentMethod.card(),
    PaymentMethod.wallet(type: WalletType.applePay),
  ],
  onPay: (method) => gateways.checkout(
    intent: intent,
    method: method,
    context: context,
  ),
);
```

## Don't forget

- **Re-using intent ids on retry**: each `PaymentIntent.id` should be unique. Don't reuse the same id for retries; the gateway will treat them as the same intent and may reject the second attempt.
- **Showing the result**: always render a `PaymentResultDialog` (or your own UI) on the result. Silent failures confuse users.
- **Confirming server-side**: don't trust the client's `PaymentSuccess` alone — wait for the webhook before fulfilling expensive goods.
