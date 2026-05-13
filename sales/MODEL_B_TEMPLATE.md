# Sales Model B — Template App (CodeCanyon-style)

## What's for sale

`/template_app` — a production-ready Flutter checkout app that:

- Uses the `payment_gateways` package end-to-end.
- Includes ~20 pre-built widgets (cart, line items, address, methods, thank-you screen).
- Supports light & dark themes out of the box.
- Builds cleanly on Android, iOS, Web, Linux, macOS, Windows.
- Ships with sample integration code for Stripe + Paymob + Fawry.
- Includes Arabic / RTL support and locale-aware money formatting.

## Pricing

| Tier | Price | Includes |
|---|---|---|
| Standard | $79 | Source, install docs |
| Plus | $149 | + 30-day email support, customization tutorials |
| Lifetime | $249 | + Updates forever, priority support |

Tax included where applicable. CodeCanyon takes 30% on their listings; Gumroad takes 10%.

## Distribution

| Channel | Cut | Reach | Notes |
|---|---|---|---|
| CodeCanyon (envato) | 30% (50% non-exclusive) | ~50k template buyers/month | Big audience, slow listing approval |
| Gumroad | 10% | Direct buyers | Higher margin, requires own marketing |
| Direct (marketing-site) | 0% (just Stripe fees ~2.9%) | High-intent visitors | Best margin |

## Why buyers buy

The target buyer is one of:

1. **Solo founder** building a Flutter app from scratch. Wants to skip 2 weeks of plumbing. Pays $79 happily.
2. **Agency** running multiple client projects. Buys Lifetime, reuses across clients. Pays $249 once.
3. **Indie hacker** who needs a working checkout in 1 day. Pays $149 with support.

The competition on CodeCanyon is mostly Stripe-only or PayPal-only templates priced $20–60. **MENA payment support** is the differentiator — there's no comparable template at the time of writing.

## Listing optimization

- **Title**: "Flutter Checkout Template — 6 Gateways, MENA Ready"
- **Cover screenshot**: split-screen showing card / Vodafone Cash / Fawry / Apple Pay flows.
- **Video preview (90s)**: walk through one checkout in each region.
- **Tags**: flutter, checkout, payment, stripe, paymob, mena, egypt, arabic, mobile.
- **Demo link**: hosted Flutter web demo at `marketing-site/demo`.

## Conversion targets (year 1, conservative)

| Tier | Listings views | Conversion | Buyers | Net revenue |
|---|---|---|---|---|
| Standard | 8,000 | 0.5% | 40 | $40 × 70% × 40 = $1,120 |
| Plus | 8,000 | 0.3% | 24 | $149 × 70% × 24 = $2,503 |
| Lifetime | 8,000 | 0.2% | 16 | $249 × 70% × 16 = $2,788 |
| **Total** | 8,000 | 1.0% | 80 | **$6,411** |

CodeCanyon's reported conversion benchmark for premium Flutter templates is 0.8%–1.5%; we model at the conservative end.

## Support load

Pricing assumes ~5 minutes of support per Standard buyer, ~30 minutes per Plus buyer, ~10 minutes/month per Lifetime buyer. At 80 buyers / year:

- Standard: 40 × 5 min = 3.3h
- Plus: 24 × 30 min = 12h
- Lifetime: 16 × 10 min × 12 = 32h

Total: ~47h/year of support load. At $50/h labor cost = $2,350. Profit margin: ~63%.

## Refunds and returns

CodeCanyon honors 7-day refunds. Direct sales offer 14-day. Expected refund rate: ~5%.

## Upsells

- Buyer of Standard → upgrade to Lifetime (pay difference, $170).
- Buyer of Lifetime → upsell to Backend Bundle Self-Hosted ($499) when they need webhooks. This is the natural funnel into Model C.
