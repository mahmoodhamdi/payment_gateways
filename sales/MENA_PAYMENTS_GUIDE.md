# MENA Payments — Buyer's Guide

Why building MENA SaaS or e-commerce without MENA-native gateways will hit a wall, and how this bundle solves it.

## The MENA payment reality

The MENA region — Egypt, Saudi Arabia, UAE, Kuwait, Qatar, Bahrain, Oman, Jordan, Lebanon — has a fundamentally different payment landscape than the West.

| Market | Card penetration | Primary payment method | Right gateway |
|---|---|---|---|
| Egypt | ~25% | Vodafone Cash + Fawry cash + cards | Paymob + Fawry |
| Saudi Arabia | ~85% | mada (national network) + cards | PayTabs + Stripe |
| UAE | ~80% | cards + Apple Pay | PayTabs + Stripe |
| Kuwait | ~75% | K-Net + cards | PayTabs |
| Lebanon | ~10% | cash + crypto-converted USDT | Custom (out of scope v0.1) |

A "global Stripe-only" checkout misses 30–80% of available customers in these markets.

## What's special about MENA gateways

### Paymob (Egypt)

- Accepts Visa, Mastercard, **plus** mobile wallets (Vodafone Cash, Orange Cash, Etisalat Cash).
- Iframe-hosted flow → simple PCI scope.
- HMAC SHA-512 webhook signing.
- Settlement in EGP (Egyptian Pound).

### Fawry (Egypt)

- Cash-at-outlet network covering 150,000+ locations.
- Required for ~40% of Egyptians who don't carry payment cards.
- Reference-number-based — async confirmation via webhook hours to days later.
- Critical for B2C apps with mass-market reach.

### PayTabs (Saudi/Gulf)

- Accepts mada (Saudi national debit network), Apple Pay, Visa, Mastercard.
- Multi-currency: SAR, AED, KWD, BHD, QAR, OMR, EGP.
- Hosted PayPage iframe.
- Strong fraud prevention with regional context.

### Why a single global gateway doesn't cut it

- Stripe doesn't support mada (Saudi domestic). PayTabs does.
- Stripe doesn't accept Vodafone Cash. Paymob does.
- Stripe can't issue cash-pay-at-Fawry references. Fawry does (only).
- Currency: Stripe charges 1% currency conversion on EGP → USD round trips. Paymob settles natively in EGP, no conversion.

## How `payment_gateways` handles MENA

The package's **smart router** automatically routes:

| Customer country | Method requested | Routed to |
|---|---|---|
| EG | card | Paymob (preferred) |
| EG | vodafone_cash | Paymob |
| EG | cash | Fawry |
| SA | card | PayTabs |
| SA | mada | PayTabs |
| AE | apple_pay | PayTabs |
| US | card | Stripe |
| GB | card | Stripe |
| NG | card | (v1.1 — Opay) |

You pass the same `PaymentMethod.card()` regardless of country; the router picks the best gateway. Or pin one explicitly with `pinGatewayId: 'paymob'`.

## Settlement & withdrawal

| Gateway | Settlement window | Withdrawal frequency |
|---|---|---|
| Paymob | T+3 business days | Weekly |
| Fawry | T+4 business days | Bi-weekly |
| PayTabs | T+2 business days | Daily |
| Stripe MENA | T+7 to T+30 (depends on country) | Daily after warmup |

For cashflow-sensitive businesses, prefer Paymob/PayTabs over Stripe in MENA.

## Currency conversion gotchas

- Paymob settles in EGP only. If you bill USD prices, convert client-side and pass `currency: Currency.egp` with the EGP equivalent. Use a daily-refreshed FX rate from XE or ExchangeRates-API.
- PayTabs settles in each Gulf currency natively. No conversion needed if you bill in SAR/AED/etc.
- Stripe converts at their daily rate + 1% spread; documented in the dashboard.

## VAT / tax considerations

- Egypt: 14% VAT on most digital goods.
- Saudi Arabia: 15% VAT.
- UAE: 5% VAT.
- Add tax IDs to `OrderMetadata.tags`; receipts should include the VAT line.

The package doesn't compute tax — that's your application's job. See [`docs/recipes/tax_handling.md`](../docs/recipes/tax_handling.md) for the recommended pattern (v0.5).

## Recommended bundle for MENA SaaS

| Audience | Recommended gateways | Bundle tier |
|---|---|---|
| Egypt B2C app | Paymob + Fawry + Stripe (fallback for tourists) | Self-Hosted ($499) |
| Saudi/Gulf B2B SaaS | PayTabs + Stripe | Pro ($1,499) |
| Multi-region MENA | All 4: Paymob + Fawry + PayTabs + Stripe | Pro ($1,499) |
| Marketplace with escrow | Paymob (split routing) + Fawry | Enterprise (custom) |

Email mahmoud.softwars@gmail.com for a recommendation based on your specific market and volume.
