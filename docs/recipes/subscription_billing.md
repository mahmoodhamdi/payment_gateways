# Recipe: Subscription billing

v0.1 ships native subscription support for **Stripe** and **PayPal** only. For Paymob / PayTabs / Fawry / Square, subscriptions are orchestrated by your backend on a cron schedule. v0.5 will ship a reusable `SubscriptionModule` that abstracts both.

## Stripe — native subscriptions

Backend:

```ts
// backend_companion/src/routes/subscriptions.ts (sketch)
router.post('/subscriptions', async (req, res) => {
  const stripe = new Stripe(env.STRIPE_SECRET_KEY);
  const sub = await stripe.subscriptions.create({
    customer: req.body.customer_id,
    items: [{ price: req.body.price_id }],
    payment_behavior: 'default_incomplete',
    expand: ['latest_invoice.payment_intent'],
  });
  res.json({
    subscription_id: sub.id,
    client_secret: (sub.latest_invoice as Stripe.Invoice & {
      payment_intent: Stripe.PaymentIntent;
    }).payment_intent.client_secret,
  });
});
```

Flutter:

```dart
// Treat the returned client_secret like a one-time PaymentIntent.
final result = await gateways.checkout(
  intent: PaymentIntent(
    id: subscription.id,
    amountMinorUnits: subscription.firstInvoiceAmount,
    currency: subscription.currency,
    customer: customer,
    clientSecret: response.clientSecret,
  ),
  method: const PaymentMethod.card(),
  context: context,
);
```

Webhook handling:

- `customer.subscription.created`
- `invoice.paid` → mark subscription active
- `invoice.payment_failed` → enter grace period
- `customer.subscription.deleted` → cancel
- `customer.subscription.trial_will_end` → notify

## Paymob / PayTabs — orchestrated by backend cron

Paymob does not support native recurring tokens via its hosted iframe. The pattern:

1. First charge runs through the standard `payment_gateways` flow.
2. On success, the backend stores the customer + tokenized card reference (if Paymob's "saved cards" feature is enabled for your merchant).
3. A nightly cron creates a fresh order + payment_key for next-month's renewal using the saved token.
4. If the saved-token charge fails, enter your dunning flow.

Saved-token requires Paymob's "Tokenization" feature to be enabled — talk to Paymob support to provision.

## Fawry — non-recurring by design

Fawry cash payments cannot be automated. For Fawry subscribers:

- Send a reminder email/SMS 3 days before renewal with a fresh reference number.
- Mark the subscription "awaiting cash" once the new reference is issued.
- Confirm on webhook.

## v0.5 — `SubscriptionModule` (planned)

```dart
final subs = gateways.subscriptions;

final sub = await subs.start(
  customer: customer,
  plan: const SubscriptionPlan(
    name: 'Pro',
    amountMinorUnits: 999,
    currency: Currency.usd,
    interval: SubscriptionInterval.monthly,
    trialDays: 14,
  ),
);

// Backend takes care of native (Stripe) vs orchestrated (Paymob) under
// the hood; the API surface is identical.
```

Track progress in [issue #SUB-1](https://github.com/mahmoodhamdi/payment_gateways/issues).

## Don't forget

- **Charge attempt frequency**: failed Stripe renewals automatically retry per your dunning schedule. For orchestrated gateways, your cron must implement retry/backoff (1d, 3d, 7d typical).
- **Proration**: handle upgrades/downgrades carefully; Stripe does it natively, orchestrated gateways need manual calculation.
- **VAT / tax**: include tax IDs in `OrderMetadata.tags` so receipts comply with local invoice requirements.
- **Cancellation**: surface a one-click cancel in your app or you'll get chargebacks.
