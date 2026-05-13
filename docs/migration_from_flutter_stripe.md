# Migrating from `flutter_stripe`

If you're already integrated with the official `flutter_stripe` package and want to add Paymob / Fawry / PayTabs without rewriting the Stripe parts, this guide walks you through the migration path.

## High-level mapping

| `flutter_stripe` | `payment_gateways` |
|---|---|
| `Stripe.publishableKey = 'pk_test_...'` | `GatewayConfig.stripe(publishableKey: 'pk_test_...')` |
| `Stripe.instance.confirmPayment(...)` | `gateways.checkout(intent: ..., method: const PaymentMethod.card())` |
| `Stripe.instance.presentApplePay(...)` | v1.1 (planned — see [`docs/gateways/stripe.md`](gateways/stripe.md)) |
| `setupIntents.confirmSetupIntent(...)` | v0.5 `SubscriptionModule` |
| `webhook events on your backend` | `/webhooks/stripe` on `backend_companion` |

## Step 1: keep Stripe as the default gateway

Configure only Stripe at first. Verify your existing Stripe flow still works under `payment_gateways`.

```dart
final gateways = PaymentGateways(
  config: PaymentConfig(
    environment: Environment.test,
    gateways: {
      'stripe': GatewayConfig.stripe(publishableKey: 'pk_test_...'),
    },
    backendBaseUrl: Uri.parse('https://your-backend.example.com'),
  ),
  gatewayBuilders: const [StripeGateway.builder],
);
```

## Step 2: move secret keys to the backend

The biggest behavioural difference: this SDK refuses to handle secret keys on the client. If you currently have `Stripe.publishableKey` and call `confirmPayment` directly from the app, you also need a server with `STRIPE_SECRET_KEY` that the SDK can talk to.

Stand up `backend_companion` (see [`backend_companion/README.md`](../backend_companion/README.md)). Move:

- `stripe.paymentIntents.create(...)` → `POST /api/checkout` on backend.
- `stripe.paymentIntents.confirm(...)` → backend's `confirmCard()`.
- Webhook handlers (`charge.succeeded`, etc.) → `POST /webhooks/stripe`.

The backend ships idempotent handlers for the most common events out of the box.

## Step 3: replace `Stripe.confirmPayment`

Before:

```dart
await Stripe.instance.confirmPayment(
  paymentIntentClientSecret: clientSecret,
  data: PaymentMethodParams.card(...),
);
```

After:

```dart
final intent = PaymentIntent(
  id: orderId,
  amountMinorUnits: amount,
  currency: Currency.parse(currency),
  customer: Customer(id: userId, email: userEmail),
  clientSecret: clientSecret,
);
final result = await gateways.checkout(
  intent: intent,
  method: const PaymentMethod.card(),
  context: context,
);
```

## Step 4: handle the result with sealed pattern matching

`flutter_stripe` throws exceptions on failure; `payment_gateways` returns sealed `PaymentResult` variants.

Before:

```dart
try {
  await Stripe.instance.confirmPayment(...);
  showSuccess();
} on StripeException catch (e) {
  showError(e.error.localizedMessage);
}
```

After:

```dart
switch (result) {
  case PaymentSuccess(): showSuccess();
  case PaymentFailure(error: InsufficientFundsError()):
    showError('Not enough balance');
  case PaymentFailure(error: ExpiredCardError()):
    showError('Card expired');
  case PaymentFailure(:final error):
    showError(error.userMessage);
  case PaymentCanceled():
    // user backed out
    break;
  case PaymentPendingAction():
    // shouldn't happen for plain card; handled internally for 3DS
    break;
}
```

## Step 5: add Paymob (or any other gateway)

This is where the value shows up. Add the new gateway to `config.gateways`:

```dart
gateways: {
  'stripe': GatewayConfig.stripe(publishableKey: 'pk_test_...'),
  'paymob': GatewayConfig.paymob(
    publicKey: '',
    integrationIds: {'card': 12345, 'mobile_wallet': 67890},
    iframeId: '12345',
  ),
},
gatewayBuilders: const [
  StripeGateway.builder,
  PaymobGateway.builder,
],
```

The router now sends Egyptian customers to Paymob automatically. No code changes in your checkout screen.

## Things that get easier

- One result type (`PaymentResult`) instead of throwing exceptions.
- One `Customer` model instead of gateway-specific shapes.
- One webhook backend that hosts handlers for every gateway you add.
- Typed error matching (`PaymentError` subclasses).
- Consistent test infrastructure (`MockPaymentGateway` available in tests).

## Things you give up

- Stripe Apple Pay / Google Pay are deferred to v1.1 in this SDK (still possible by keeping `flutter_stripe` for that one flow).
- You no longer call Stripe's API directly from Flutter — adds one hop through your backend.

## Recommended order

1. Stand up `backend_companion` with Stripe-only.
2. Replace `Stripe.confirmPayment` calls one by one.
3. Once all card flows are migrated, remove `flutter_stripe` from `pubspec.yaml` (or keep it solely for wallet flows).
4. Add Paymob / Fawry / PayTabs as separate PRs, one per gateway.
