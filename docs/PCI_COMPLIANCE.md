# PCI-DSS Awareness Guide

> **TL;DR**: With this SDK, your integration likely qualifies for the simplest PCI-DSS self-assessment (**SAQ A**) because all card data goes through gateway-hosted iframes or the backend's tokenization endpoint — never persisted in your app or backend in raw form.

This is **not** legal advice and **not** an official PCI-DSS auditor opinion. Consult a QSA (Qualified Security Assessor) before launching at scale. The notes below explain the technical scope reduction this SDK gives you.

## What is PCI-DSS?

The Payment Card Industry Data Security Standard. Twelve high-level requirements that anyone storing, processing, or transmitting cardholder data must meet to avoid penalties from card networks (Visa, Mastercard, etc.).

Merchant levels (per Visa):

| Level | Annual Visa transactions | Assessment |
|---|---|---|
| 1 | > 6M | Full on-site audit by a QSA, quarterly ASV scans |
| 2 | 1M – 6M | SAQ + quarterly ASV scans |
| 3 | 20k – 1M (e-commerce) | SAQ + quarterly ASV scans |
| 4 | < 20k (e-commerce) | SAQ + quarterly ASV scans |

For most apps starting out, this means a **Self-Assessment Questionnaire (SAQ)**.

## SAQ types (relevant ones)

| SAQ | Applies when | Effort |
|---|---|---|
| **A** | E-commerce merchant who outsources card handling entirely (e.g. iframe, redirect, hosted payment page). **No card data touches your servers.** | Smallest: ~22 questions. |
| **A-EP** | E-commerce where your page receives the card data (even via JavaScript) and forwards to a service provider. | Medium: ~191 questions. |
| **D** | Anyone who stores, processes, or transmits card data themselves. | Largest: ~329 questions + full security program. |

**Goal**: stay in SAQ A.

## How this SDK keeps you in SAQ A

### 1. Card data is never bundled with your code

The `CardInput` widget in this package is a **fallback** for gateways that don't have a hosted iframe. Even then, raw card details only ever pass through:

- Memory in the Flutter app for the duration of one checkout flow (controllers are explicitly cleared on dispose).
- The TLS pipe to your backend `/api/checkout/confirm`.
- Your backend's call to the gateway's SDK (no local persistence).

**The preferred flow** is to use the gateway's hosted form (Stripe Elements, Paymob iframe, PayTabs PayPage). When you do that, the card data goes from the user's keyboard directly to the gateway over TLS, never touching your code.

### 2. Backend never persists raw cards

- The `/api/checkout/confirm` route handler never writes raw card details to disk.
- The Pino logger redacts `card.number`, `card.cvv`, `card.exp_month`, `card.exp_year` from every log entry.
- The shared `redact()` utility on both Flutter and Node.js sides recognizes 30+ sensitive field names.

### 3. Secret API keys never ship in client code

- `GatewayConfig.stripe()` validates that the key starts with `pk_` and rejects `sk_*` at construction.
- The Flutter package never imports a gateway secret SDK.
- All `/api/refunds`, `/api/transactions/:id`, and webhook signature verification happen on the backend.

### 4. Webhook signatures are verified, replays rejected

Every webhook handler:

1. Reads the raw body before JSON parsing.
2. Computes the HMAC and compares with the gateway-provided signature.
3. Checks the event id against the idempotency store — duplicates short-circuit.

This is required by PCI-DSS Requirement 4 (encrypt transmission of cardholder data over open networks).

### 5. HTTPS-only

`PaymentConfig.validate()` throws if `backendBaseUrl` is `http://` in production. The Flutter app refuses to boot with a misconfigured prod URL.

## What you still need to do

This SDK reduces scope. It does not eliminate it. You still need to:

- **TLS at the deployment layer**: terminate HTTPS at NGINX / your cloud LB with a valid certificate (auto-renewed via Let's Encrypt is fine).
- **Network segmentation**: the backend that holds gateway secret keys should not be the same host as your unrelated services; use a dedicated VPC / firewall rule.
- **Logging**: enable Pino's redact (already configured) and ensure your hosting platform doesn't capture raw request bodies somewhere upstream.
- **Quarterly ASV scans**: required by all SAQ tiers. Approved Scanning Vendors include SecurityMetrics, Qualys, Trustwave.
- **Annual SAQ renewal**: even if nothing changed.

## When you need SAQ D

You leave SAQ A territory and enter SAQ D if you:

- Store raw card numbers (even encrypted) in your DB.
- Process card data with a stack you wrote yourself (e.g. directly send to acquirer banks).
- Forward card data to a non-gateway service (e.g. an analytics tool).
- Are an ISO/MSP (re-selling card processing to other merchants).

If you find yourself wanting to do any of these — talk to a QSA first.

## Resources

- [PCI-DSS v4.0.1 (official)](https://www.pcisecuritystandards.org/document_library)
- [Stripe's PCI guide](https://stripe.com/docs/security)
- [SAQ A questionnaire (PDF)](https://www.pcisecuritystandards.org/documents/PCI_DSS_SAQ_A_Rev1-3.pdf)

## Auditor questions you might face

When a QSA asks "Do you store cardholder data?" — your answer is:

> No. Our application uses the [Stripe / Paymob / etc.] hosted payment page for all card capture. Raw cardholder data is never transmitted to or stored by our infrastructure. We use the [payment_gateways SDK + backend] which enforces this architecturally.

Then point them at:

- This document.
- `package/lib/src/utils/sensitive_fields.dart` (the redaction registry).
- `backend_companion/src/lib/redact.ts` (server-side mirror).
- `package/lib/src/core/gateway_config.dart` (publishable-key validation).
