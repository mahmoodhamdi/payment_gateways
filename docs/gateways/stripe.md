# Stripe — Setup Guide

Stripe is the most fully-implemented gateway in v0.1. Use it as the global default; pair with Paymob/Fawry/PayTabs for regional coverage.

## 1. Get credentials

1. Sign in at [https://dashboard.stripe.com](https://dashboard.stripe.com).
2. Toggle to **Test mode** (top-right) during development.
3. **Developers → API keys**: copy the **Publishable key** (`pk_test_...`) and **Secret key** (`sk_test_...`).
4. **Developers → Webhooks** → "Add endpoint":
   - URL: `https://your-backend.example.com/webhooks/stripe`
   - Events: `payment_intent.succeeded`, `payment_intent.payment_failed`, `charge.refunded`.
   - Copy the **Signing secret** (`whsec_...`).

## 2. Configure the backend

In `backend_companion/.env.local`:

```bash
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
```

Restart the backend. `GET /health` should now include `"stripe"` in `gateways_configured`.

## 3. Configure the Flutter app

```dart
final gateways = PaymentGateways(
  config: PaymentConfig(
    environment: Environment.test,
    gateways: {
      'stripe': GatewayConfig.stripe(
        publishableKey: 'pk_test_...',
        merchantIdentifier: 'merchant.com.your-app', // optional — Apple Pay
      ),
    },
    backendBaseUrl: Uri.parse('https://your-backend.example.com'),
  ),
  gatewayBuilders: const [StripeGateway.builder],
);
```

**Never** put `sk_test_...` or `sk_live_...` in Flutter code. The SDK validates and refuses keys starting with `sk_`.

## 4. Test cards

| Card | Expected behavior |
|---|---|
| `4242 4242 4242 4242` | Successful charge |
| `4000 0027 6000 3184` | Requires 3-D Secure |
| `4000 0000 0000 9995` | Insufficient funds |
| `4000 0000 0000 0002` | Declined |
| `4000 0000 0000 0069` | Expired |

CVV: any 3 digits. Expiry: any future date.

## 5. 3-D Secure flow

When Stripe returns `requires_action`, our backend forwards the `redirect_to_url.url` as `action_url`. The Flutter `StripeGateway` opens it in `ThreeDSWebView` and watches for the merchant return URLs:

- `https://payment-gateways.local/stripe/success`
- `https://payment-gateways.local/stripe/failure`

Configure these as the `return_url` on your PaymentIntent **on the backend** — the included `StripeAdapter.confirmCard` already does that.

## 6. Apple Pay / Google Pay (v1.1)

Currently the adapter returns a `ConfigError` for wallet methods. To enable in v1.1:

1. Add `flutter_stripe` to `template_app/pubspec.yaml`.
2. Configure Apple Pay merchant ID + Google Pay environment.
3. Update `StripeGateway._runWalletFlow` to call `Stripe.instance.presentApplePay(...)` / `presentGooglePay(...)`.

See [`docs/recipes/wallets_v1_1_preview.md`](../recipes/wallets_v1_1_preview.md) for the planned API.

## 7. Going to production

- [ ] Switch keys to live (`pk_live_...`, `sk_live_...`).
- [ ] Use a real webhook URL with HTTPS.
- [ ] Verify the `STRIPE_WEBHOOK_SECRET` matches the **live** signing secret (not the test one).
- [ ] Enable **Stripe Radar** in the dashboard for fraud detection.
- [ ] Confirm your business is approved in all currencies you accept.
- [ ] Subscribe to Stripe's developer changelog for breaking API changes.

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| 3DS WebView never closes | Backend `return_url` doesn't include the success/failure prefix the adapter watches. |
| Webhook signature invalid | Mixing test and live webhook secrets. Each environment has its own. |
| `card_declined` on Visa 4242… | You're in live mode. Switch to test mode to use test cards. |
| `automatic_payment_methods` not allowed | Older Stripe API version; remove `apiVersion` pin (the adapter doesn't pin one). |
