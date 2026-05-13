# Support Plans

## What's included by tier

| | MIT (free) | Indie | Studio | Enterprise | Self-Hosted | Pro | Enterprise (Backend) |
|---|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| GitHub Issues | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Email support | — | 30d | 90d | 12mo | 30d | 90d | 12mo |
| Slack channel | — | — | ✓ | ✓ | — | ✓ | ✓ |
| Response SLA | — | best | 24h | 4h | 24h | 4h | 1h |
| On-call hours | — | — | — | 4h/mo | — | — | 4h/mo |
| Custom adapter | — | — | — | up to 8h/yr | — | 8h | up to 40h/yr |
| Priority queue | — | — | ✓ | ✓ | — | ✓ | ✓ |
| Refunds in case of bug | — | per case | per case | within SLA | per case | within SLA | within SLA |

## What we will help with

- Installing the package, configuring the backend.
- Debugging gateway-specific webhook signature mismatches.
- Reading your logs and explaining what went wrong.
- Suggesting routing rules for your customer demographics.
- Reviewing PRs in your own fork (within reason).
- Writing custom gateway adapters (paid tiers).
- Recommending PCI-DSS scope reductions in your architecture.

## What we won't help with

- Getting your account approved at Stripe/Paymob/etc. — that's between you and the gateway.
- Tax / accounting / regulatory advice.
- Compliance certifications for your deployment (SOC 2, ISO 27001).
- Custom legal terms beyond the commercial license templates.
- Marketing your app.

## How to file a support request

| Severity | Channel | Expected response |
|---|---|---|
| Production outage | Slack `#sev1` (Pro+) or email subject `URGENT` | within SLA |
| Bug, no workaround | GitHub Issue with `severity-medium` label | within SLA |
| Bug, has workaround | GitHub Issue with `severity-low` label | best-effort |
| Feature request | GitHub Issue with `enhancement` label | reviewed weekly |
| Question | Slack or email | best-effort |

Include in every support request:

1. SDK version (`payment_gateways: ^0.x.y`).
2. Backend version (commit SHA or release tag).
3. Gateway involved.
4. Test or production environment.
5. Redacted logs (timing, error codes, no PAN/CVV).
6. Minimal repro if applicable.

## Office hours

Mahmoud holds open office hours for Pro+ customers — 1 hour, weekly, by appointment. Schedule via the shared Slack.

## Renewal

- Annual contracts auto-renew 30 days before expiry.
- 14-day notice required to downgrade or cancel.
- Custom adapter hours don't carry over year-to-year.
