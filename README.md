# payment_gateways

> **A unified Flutter SDK for integrating multiple payment gateways — global and MENA-first.**

[![Pub Version](https://img.shields.io/pub/v/payment_gateways.svg)](https://pub.dev/packages/payment_gateways)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![CI](https://github.com/mahmoodhamdi/payment_gateways/actions/workflows/ci.yml/badge.svg)](https://github.com/mahmoodhamdi/payment_gateways/actions)
[![Coverage](https://img.shields.io/badge/coverage-pending-yellow.svg)](#testing)

One SDK, one checkout UI, one webhook handler — across Stripe, PayPal, Paymob, Fawry, PayTabs, Square, 2Checkout, and Opay. First-class support for the MENA region (Egypt, Saudi Arabia, UAE, Kuwait).

---

## What's in this repository

This is a monorepo with three deliverables:

| Folder | Description | Audience |
|---|---|---|
| [`package/`](./package) | Flutter package, publishable on pub.dev | Flutter developers integrating payments |
| [`template_app/`](./template_app) | Production-ready checkout template app | Buyers of a turnkey checkout app |
| [`backend_companion/`](./backend_companion) | Node.js + TypeScript backend (webhooks, signing, dashboard) | Teams needing a secure server-side payment layer |

---

## Supported Payment Gateways

### v1 (production-ready)

| Gateway | Region | Card | Wallet | 3DS | Subscriptions | Refunds |
|---|---|:-:|:-:|:-:|:-:|:-:|
| **Stripe** | Global | yes | Apple Pay, Google Pay, Link | yes | native | yes |
| **Paymob** | Egypt | yes | Vodafone Cash, Orange Cash, Etisalat Cash | yes | orchestrated | yes |
| **PayTabs** | Saudi / Gulf | yes (mada) | Apple Pay | yes | orchestrated | yes |
| **Fawry** | Egypt | yes | — | n/a | orchestrated | yes |
| **PayPal** | Global | yes | PayPal wallet | yes | native | yes |
| **Square** | US / UK / CA / AU | yes | Apple Pay, Google Pay | yes | native | yes |

### v1.1 (planned)

| Gateway | Region | Status |
|---|---|---|
| **2Checkout (Verifone)** | Global reseller | Deferred — pending stable test sandbox |
| **Opay** | Nigeria / West Africa | Deferred — pending complete English documentation |

---

## Quick start (package)

Add `payment_gateways` to your Flutter app:

```yaml
dependencies:
  payment_gateways: ^0.1.0
```

Initialize and accept a payment in four lines:

```dart
import 'package:payment_gateways/payment_gateways.dart';

final gateways = PaymentGateways(
  config: PaymentConfig.fromEnv(), // reads test/prod keys from your secure store
);

final result = await gateways.checkout(
  intent: PaymentIntent(amountMinorUnits: 4999, currency: 'USD', /* ... */),
  context: context,
);
```

See the [package README](./package/README.md) for full setup, per-gateway guides, and recipes.

---

## Why this exists

- Most Flutter projects roll one-off integrations per gateway. The maintenance and 3DS / webhook handling burden multiplies.
- `flutter_stripe`, `flutter_paypal`, and the like solve one gateway each. Nothing unifies them at the API or UI level.
- MENA payment gateways (Paymob, Fawry, PayTabs) are underserved by the global Flutter ecosystem — and they are precisely the rails most of MENA actually pays through.
- Webhooks need server-side signature verification and idempotency. A package alone can't do that — so this repo also ships a Node.js backend you can drop next to your gateway.

---

## Repository layout

```
payment_gateways/
├── package/              Flutter package — public API + adapters + UI widgets
│   ├── lib/
│   ├── example/
│   ├── test/
│   └── pubspec.yaml
├── template_app/         Standalone Flutter app — full checkout template
│   ├── lib/
│   ├── android/ ios/ web/ linux/ macos/ windows/
│   └── pubspec.yaml
├── backend_companion/    Node.js + TypeScript backend
│   ├── src/
│   ├── tests/
│   └── package.json
├── docs/                 Setup guides, recipes, portfolio integration notes
├── scripts/              Dev tooling
└── .github/workflows/    CI for analyze / test / build / security / release
```

---

## Getting started (contributors)

```bash
# Clone
git clone https://github.com/mahmoodhamdi/payment_gateways.git
cd payment_gateways

# Package
cd package && flutter pub get && flutter analyze && flutter test
cd ..

# Template app
cd template_app && flutter pub get && flutter run
cd ..

# Backend
cd backend_companion && npm install && npm run dev
cd ..
```

---

## Documentation

- [Per-gateway setup guides](./docs/gateways/)
- [Recipes](./docs/recipes/) — one-time, subscription, marketplace, donation, Fawry cash-on-delivery, multi-currency
- [Backend setup](./backend_companion/README.md) — Docker, secret management, webhook signatures
- [Migration from `flutter_stripe`](./docs/migration_from_flutter_stripe.md)
- [PCI-DSS awareness](./docs/PCI_COMPLIANCE.md)

---

## Licensing

- **Package** (`/package`): MIT — free to use in commercial apps, no attribution required.
- **Template app** (`/template_app`): Commercial license required. See [`sales/`](./sales) for terms.
- **Backend companion** (`/backend_companion`): Commercial license required (Self-Hosted, Pro, Enterprise tiers).

For the package alone, attribution is not required. For the template + backend, a commercial license is mandatory.

---

## Status & roadmap

- [x] v0.1.0 — core abstractions, Stripe + Paymob adapters, backend skeleton
- [ ] v0.5.0 — PayPal, Fawry, PayTabs adapters; admin dashboard
- [ ] v1.0.0 — Square; multi-platform builds; pub.dev publish
- [ ] v1.1.0 — Opay, 2Checkout

---

## Support

- Issues: [GitHub Issues](https://github.com/mahmoodhamdi/payment_gateways/issues)
- Commercial support: see [`sales/SUPPORT_PLANS.md`](./sales/SUPPORT_PLANS.md)
- Security disclosures: see [`SECURITY.md`](./SECURITY.md)
