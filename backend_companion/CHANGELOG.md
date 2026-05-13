# Changelog — backend_companion

## [Unreleased]

### Planned

- MongoDB-backed `TransactionStore`.
- Redis-backed `IdempotencyStore`.
- Per-tenant API key rotation + DB.
- Stripe Apple Pay / Google Pay via native SDKs (server-side counterpart).
- 2Checkout and Opay adapters.

## [0.1.0] - 2026-05-13

Initial release alongside `payment_gateways@0.1.0`.

- Express + TypeScript backend with Pino logging.
- Six gateway adapters: Stripe, Paymob, PayTabs, Fawry, PayPal, Square.
- Webhook routes per gateway with signature verification + idempotency.
- `/api/checkout`, `/api/checkout/confirm`, `/api/transactions/:id`, `/api/refunds`.
- Admin dashboard JSON: `/api/dashboard/transactions` and `/api/dashboard/analytics`.
- Health check exposing which gateways are configured.
- Docker + Docker Compose for one-command deploy.
- In-memory transaction store + idempotency store (production swappable).
