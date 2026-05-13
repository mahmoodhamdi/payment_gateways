# Changelog

All notable changes to `payment_gateways` are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and
this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Initial monorepo restructure (`package/`, `template_app/`, `backend_companion/`).
- Core payment abstractions:
  - `PaymentMethod` sealed union (card, wallet, cash, bank transfer).
  - `PaymentIntent`, `Customer`, `OrderMetadata`, `Address` immutable models.
  - `PaymentResult` sealed union (`success`, `failure`, `canceled`, `pendingAction`).
  - `PaymentError` typed errors (`insufficientFunds`, `cardDeclined`, `expiredCard`, `invalidCvv`, `threeDSecureFailed`, `network`, `gatewayUnavailable`, `misconfiguration`, `unknown`).
- `PaymentGateway` abstract adapter interface.
- `PaymentRouter` smart-routing based on country, currency, method preference.
- `PaymentConfig` env-driven configuration.
- Reusable UI widgets: `CheckoutForm`, `PaymentMethodSelector`, `CardInput`, `WalletButtons`, `OrderSummary`, `PaymentResultDialog`, `ThreeDSWebView`.
- Stripe adapter (production-ready).
- Paymob adapter (production-ready).

## [0.1.0] - 2026-05-13

Initial pre-release. See [Unreleased] for the in-flight work scheduled into this version.
