# Fawry — Setup Guide

Fawry is the Egyptian unbanked-customer pipeline. Roughly 40% of Egypt's population doesn't carry a payment card; Fawry lets them pay your app in cash at ~150,000 outlets, ATMs, or via their banking app.

## How Fawry differs from card gateways

| | Card / wallet | Fawry |
|---|---|---|
| When the customer pays | At checkout | Anywhere from minutes to days later |
| Settlement notification | Immediate | Webhook hours/days later |
| In-app UX | Card form → 3DS → done | Show reference number → wait |
| Refunds | Programmatic | Manual via Fawry merchant portal |

## 1. Get credentials

1. Apply at [https://fawry.com/business](https://fawry.com/business).
2. Once approved, the Fawry team emails:
   - `merchantCode`
   - `securityKey`
3. Test on staging first: `FAWRY_USE_STAGING=true` in `.env`.

## 2. Configure the backend

```bash
FAWRY_MERCHANT_CODE=...
FAWRY_SECURITY_KEY=...
FAWRY_USE_STAGING=true
```

## 3. Configure the Flutter app

```dart
'fawry': GatewayConfig.fawry(
  merchantCode: 'YOUR_CODE',
  useStaging: true,
),
```

Add `FawryGateway.builder` to `gatewayBuilders`.

## 4. The flow

```dart
final result = await gateways.checkout(
  intent: intent,
  method: const PaymentMethod.cash(type: CashType.fawryOutlet),
  context: context,
);

switch (result) {
  case PaymentPendingAction(:final reference):
    // Show this to the user.
    showFawryInstructions(reference!);
  case PaymentSuccess():
    // Unlikely on first call — Fawry typically returns pendingAction.
    confirmOrder();
  case PaymentFailure(:final error):
    showError(error.userMessage);
  case PaymentCanceled():
    // ignore
}
```

The `reference` is a 10–13 digit number that the customer takes to any Fawry outlet, ATM, or enters into their banking app's bill-pay menu. Show it prominently:

```dart
Widget showFawryInstructions(String reference) {
  return Column(
    children: [
      Text('Your Fawry reference number:'),
      SelectableText(
        reference,
        style: Theme.of(context).textTheme.displayLarge,
      ),
      Text(
        'Visit any Fawry outlet and give them this number. '
        'Your order will be confirmed once paid.',
      ),
    ],
  );
}
```

## 5. Polling for payment

After showing the reference, the app should periodically poll status:

```dart
Future<void> pollUntilPaid(String transactionId) async {
  while (true) {
    final status = await gateways.router
        .registered
        .firstWhere((g) => g.id == 'fawry')
        .getStatus(transactionId: transactionId);
    if (status == PaymentStatus.succeeded) return;
    if (status == PaymentStatus.canceled || status == PaymentStatus.failed) {
      throw PaymentError.unknown();
    }
    await Future.delayed(const Duration(minutes: 5));
  }
}
```

Better: subscribe to a backend websocket that pushes the webhook event in real time.

## 6. Webhook configuration

In your Fawry dashboard, set the callback URL:

```
https://your-backend.example.com/webhooks/fawry
```

The backend verifies the `messageSignature` field with SHA-256.

## 7. Reference number expiry

Fawry references typically expire after 24–72 hours. Configure your app to either:

- Surface a banner reminding the user the reference will expire.
- Re-issue a new reference if the user comes back.

## 8. Refunds

Fawry refunds are batch processes initiated through the merchant portal, not programmatic. The `/api/refunds` endpoint returns `false` for Fawry. Document this limitation in your customer-support flow.

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| Signature mismatch on charge create | The signature recipe varies per merchant config. Open a Fawry support ticket with your sample payload. |
| Reference number not recognized at outlet | Reference expired (>72h). Re-create. |
| Webhook never arrives | Callback URL not whitelisted in Fawry's IP allowlist. |
