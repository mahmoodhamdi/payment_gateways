# Portfolio integration playbook

This document is internal: how to drop `payment_gateways` into Mahmoud's other projects as the unified payment layer.

The pattern below is the same for every consuming project — the **only** variation is which gateway makes sense for that project's user base.

## Generic 4-step recipe

1. **Add the dependency** to `pubspec.yaml`:
   ```yaml
   dependencies:
     payment_gateways:
       git:
         url: https://github.com/mahmoodhamdi/payment_gateways
         path: package
         ref: main
   ```
   Once on pub.dev: `payment_gateways: ^0.1.0`.

2. **Deploy a shared backend** instance (or point at the existing one). Set `API_KEY` in the consuming app's env, point `BackendClient.config.backendBaseUrl` at it.

3. **Pick the gateway routing** for this project:
   - Egyptian SaaS / mobile? Paymob primary, Fawry fallback.
   - Global SaaS / web? Stripe primary, PayPal for Latin America/EU users.
   - Gulf B2B? PayTabs primary, Stripe fallback.

4. **Wire `PaymentGateways(...)` once at app startup**, expose the instance via your DI / Riverpod / GetIt provider. Use `gateways.checkout(...)` wherever you currently call your existing payment code.

## Per-project notes

### Markdown-to-PDF
- **Use case**: Pro tier (one-time $19) + Team tier ($99).
- **Recommended gateways**: Stripe (global) + Paymob (for EG users).
- **Subscription**: Stripe-native (or v0.5 SubscriptionModule).
- **Existing integration**: the project already has 4 gateways one-offs; this consolidation removes ~600 lines of code.

### whatsapp-sheets-bot
- **Use case**: Monthly subscription, $29-99/mo.
- **Recommended gateways**: Stripe.
- **Subscription**: Native Stripe Subscriptions.
- **Webhook events**: `customer.subscription.updated` → toggle bot access, `invoice.payment_failed` → 7-day grace.

### Screenshot-API
- **Use case**: API usage-based billing ($0.001 per screenshot, monthly invoice).
- **Recommended gateways**: Stripe (metered billing).
- **Implementation note**: Backend cron reads usage_records, posts to Stripe Subscription Items.

### wasalni
- **Use case**: Passenger pays driver via app; weekly driver payouts.
- **Recommended gateways**: Paymob (passenger) + manual bank transfer (drivers; Paymob Payouts API in v0.5).
- **Subscription**: none.
- **Custom needs**: split payment between platform and driver (talk to Paymob support to enable split-routing).

### sana3y
- **Use case**: Marketplace transactions with escrow.
- **Recommended gateways**: Paymob (cards) + Fawry (cash) + Vodafone Cash.
- **Subscription**: none.
- **Custom needs**: hold-then-release pattern; charge customer, hold in platform account, release to vendor after delivery confirmation. This isn't trivially supported by all gateways — Paymob's "Authorization" + "Capture" two-step works.

### URL-Shortener
- **Use case**: Pro plan upgrade ($5/mo or $50/yr).
- **Recommended gateways**: Stripe + PayPal.
- **Subscription**: native Stripe + PayPal.
- **Quick win**: this is the lowest-friction project to migrate first; one button, one plan.

### QR-Code-Generator (and its vertical SaaS spin-offs)
- **Use case**: 5 vertical SaaS products with per-product subscriptions.
- **Recommended gateways**: Stripe + Paymob (each product's audience varies).
- **Subscription**: native.
- **Implementation tip**: deploy ONE `backend_companion` instance shared by all 5 verticals; use `OrderMetadata.tags['product'] = 'qr-pro'` to disambiguate revenue.

## Estimated savings

| Project | Lines saved | Hours saved | Maintenance burden removed |
|---|---|---|---|
| Markdown-to-PDF | ~600 | 40 | 4 gateway integrations consolidated |
| whatsapp-sheets-bot | ~200 | 20 | Subscription webhook handling |
| Screenshot-API | ~150 | 15 | Metered billing reconciliation |
| wasalni | ~400 | 40 | Paymob auth/order/key flow |
| sana3y | ~500 | 60 | Marketplace escrow logic |
| URL-Shortener | ~100 | 10 | Simple subscription |
| QR + verticals | ~300 × 5 = 1500 | 25 × 5 = 125 | Per-product gateway integration |
| **Total** | **~3,450 lines** | **~310 hours** | — |

At a conservative $50/hr the labor saved is **$15,500** — well above the cost of building this foundation. And every future project that needs payment gets it for free.

## Deployment topology

Two options:

### Option A: shared backend, per-project API keys
Deploy `backend_companion` once. Each consuming app has its own `API_KEY` env var. Transactions are tagged by `OrderMetadata.tags['app']`. Dashboard analytics filter by app.

Pros: cheapest. One DB, one secret store.
Cons: a bug in one app's flow can affect others.

### Option B: one backend per project
Each project has its own deployed `backend_companion`. Same code, separate state.

Pros: isolation; one tenant's traffic doesn't starve another's.
Cons: 7+ deployments to keep updated.

For Mahmoud's portfolio: **start with Option A**. Upgrade individual high-traffic projects (wasalni, sana3y) to Option B if they outgrow shared infra.
