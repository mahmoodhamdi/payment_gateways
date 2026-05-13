# payment_gateways — Master Pricing

Three sales models, priced independently. Bundles available on request.

## Model A — Package + Commercial License

> The Flutter package (`/package`) is **MIT-licensed**, free to use in commercial apps. The commercial license is for organizations that need formal terms, indemnification, or priority support.

| Tier | Price | Scope | Includes |
|---|---|---|---|
| Open-source | $0 | Any | MIT license, public issues |
| Indie Commercial | $199 / app, one-time | 1 app | Commercial license terms, email support |
| Studio Commercial | $499 / studio, one-time | Unlimited apps under one studio | Slack channel access, prioritized issues |
| Enterprise | $999 / org / year | Org-wide | SLA, named support engineer, custom adapter requests |

## Model B — Template App License

The `template_app` (standalone Flutter checkout demo) is licensed-only.

| Tier | Price | Scope | Includes |
|---|---|---|---|
| Standard | $79 | 1 product | Source code, install docs |
| Plus | $149 | 1 product | + 30-day email support, customization examples |
| Lifetime | $249 | Unlimited products | + Updates forever, priority support |

Available on CodeCanyon, Gumroad, or direct landing.

## Model C — Backend Bundle (premium)

The Node.js backend (`backend_companion`) + integrated bundle.

| Tier | Price | What you get |
|---|---|---|
| Self-Hosted | $499 | Package + backend source + 30-day setup support |
| Pro | $1,499 | + Admin dashboard, multi-tenant mode, 90-day support |
| Enterprise | $2,499 – $7,500 | + Custom adapter, 12-month support, SLA, on-call hours |
| Managed Hosting | $200–$500 / month | We run it for you on Hetzner/DO/Railway |

Enterprise pricing tiers based on:
- Transaction volume (< 50k / month = $2,499; 50k–500k = $5,000; > 500k = $7,500)
- Custom feature requests (per quote)
- SLA tier (response time)

## Bundles

| Bundle | Price | Saves |
|---|---|---|
| Studio + Self-Hosted | $899 | $99 |
| Studio + Pro | $1,799 | $199 |
| Enterprise + Pro | $2,999 | $499 |

## What's NOT included (at any tier)

- Per-gateway merchant account approval — that's between you and Stripe/Paymob/etc.
- PCI-DSS assessment by a QSA — see [`docs/PCI_COMPLIANCE.md`](../docs/PCI_COMPLIANCE.md).
- Compliance certifications (SOC 2, ISO 27001) for the customer's deployment.
- Marketing/listing creation in the customer's app stores.

## Refund policy

- Package commercial license: 14-day refund if not deployed.
- Template app: 7-day refund (CodeCanyon's policy).
- Backend bundle: 14-day setup window — if not booted within 14 days with the included support hours, full refund.

## How to buy

- **Self-checkout**: CodeCanyon for the template; landing page (`marketing-site/`) for package and backend bundles via Stripe checkout (eating our own dog food).
- **Custom / Enterprise**: email mahmoud.softwars@gmail.com.

## How we deliver

- Package: pub.dev tagged release.
- Template app: GitHub release with the APK + zipped source.
- Backend: Docker image + docs + 30/60/90-day support window starting on PO date.
