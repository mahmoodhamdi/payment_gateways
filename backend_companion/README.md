# payment_gateways — backend companion

Node.js + TypeScript backend that:

- Holds gateway **secret keys** server-side (the Flutter package never sees them).
- Tokenizes raw card details handed off from the client over TLS and confirms PaymentIntents with the gateway.
- Receives, **signature-verifies**, and idempotency-checks webhook events from every supported gateway.
- Persists transactions (in-memory v0.1, MongoDB-pluggable v0.5+).
- Exposes an admin dashboard JSON API for revenue analytics and transaction lookups.

> Pair this with the [`payment_gateways` Flutter package](../package). The package's `BackendClient` points at this server's `/api/checkout`, `/api/checkout/confirm`, `/api/transactions/:id`, and `/api/refunds`.

## Quick start

```bash
cp .env.example .env.local       # fill in your gateway secrets
npm install
npm run dev                      # http://localhost:4000
```

Or via Docker:

```bash
docker compose up -d --build
```

## Endpoints

| Method | Path | Auth | Purpose |
|---|---|---|---|
| GET | `/health` | none | Liveness + which gateways are configured |
| POST | `/api/checkout` | API key | Create a PaymentIntent on the chosen gateway |
| POST | `/api/checkout/confirm` | API key | Tokenize + confirm a card (server-side only) |
| GET | `/api/transactions/:id` | API key | Status of a known transaction |
| POST | `/api/refunds` | API key | Issue a refund |
| GET | `/api/dashboard/transactions` | API key | Admin: filterable list |
| GET | `/api/dashboard/analytics` | API key | Admin: revenue + success rate |
| POST | `/webhooks/stripe` | HMAC | Stripe events |
| POST | `/webhooks/paymob` | HMAC | Paymob callback |
| POST | `/webhooks/paytabs` | HMAC | PayTabs IPN |
| POST | `/webhooks/fawry` | SHA256 sig | Fawry order events |
| POST | `/webhooks/paypal` | PayPal verify-webhook-signature | PayPal events |
| POST | `/webhooks/square` | HMAC | Square events |

Authentication for the `/api/*` routes is a single `API_KEY` bearer token (env var). For multi-tenant deployments (the **Pro** and **Enterprise** tiers), see `docs/multi_tenant.md`.

## Webhook resilience

Every webhook handler:

1. **Reads the raw body before JSON parsing** — required for HMAC verification.
2. Verifies the signature using the gateway adapter's `verifyWebhookSignature`.
3. Looks up the event id in an idempotency store; duplicate deliveries are short-circuited with `200 OK`.
4. Translates the event to a `PaymentStatus` and updates the matching transaction.
5. Returns `200 OK` immediately — no synchronous downstream work.

The v0.1 idempotency store is in-memory (`Map`). Production deployments should swap in Redis or a unique DB constraint; the `IdempotencyStore` interface mirrors that future drop-in.

## Security

- Secret keys are loaded from environment only and never persisted. The Zod-validated `loadEnv()` rejects malformed configs at boot.
- Card data forwarded to `/api/checkout/confirm` is **never logged** — Pino's redact list filters `card.number`, `card.cvv`, `card.exp_month`, etc. The shared `redact()` utility in `src/lib/redact.ts` mirrors the Flutter side.
- HTTPS is enforced at the deployment layer (NGINX / cloud load balancer). The `payment_gateways` Flutter package refuses `http://` backend URLs in production.

## Testing

```bash
npm run test                      # full suite + coverage
npm run typecheck                 # tsc --noEmit
npm run lint                      # eslint
```

## Deployment

Tier-specific deployment guides:

- **Self-Hosted** — Docker on Hetzner / DigitalOcean / Railway. See `../docs/deploy_self_hosted.md`.
- **Pro / Multi-tenant** — see `../docs/deploy_multi_tenant.md`.
- **Managed** — talk to support for managed-hosting onboarding.

## What's NOT in v0.1

- Persistent storage (MongoDB) — in-memory only.
- Redis-backed idempotency / job queue.
- Per-tenant API keys with rotation.
- Native wallet flows (Apple Pay / Google Pay via gateway-native SDKs).
- 2Checkout and Opay gateway adapters (planned v1.1).

See [`CHANGELOG.md`](./CHANGELOG.md) for the per-version roadmap.
