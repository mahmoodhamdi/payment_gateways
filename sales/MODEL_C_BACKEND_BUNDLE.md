# Sales Model C — Backend Bundle (premium)

## What's for sale

`/backend_companion` plus the Flutter package plus support — sold as a turnkey solution.

The buyer gets a complete payments-and-webhooks stack:

- **Flutter package** (MIT, but bundled).
- **Node.js backend** (Express + TypeScript) with webhook handlers, idempotency, refunds, admin dashboard, Docker setup.
- **Setup support** (live screen-share, custom configuration).
- **Customization options** (custom gateway, multi-tenant, custom dashboard).

## Pricing tiers

| Tier | Price | Includes |
|---|---|---|
| Self-Hosted | $499 | Source + 30-day setup support |
| Pro | $1,499 | + Admin dashboard, multi-tenant, 90-day support |
| Enterprise | $2,499 – $7,500 | + Custom feature, 12-month support, SLA, on-call hours |
| Managed Hosting | $200–$500 / mo | We run it for you |

### Tier comparison

|  | Self-Hosted | Pro | Enterprise |
|---|:-:|:-:|:-:|
| Backend source | ✓ | ✓ | ✓ |
| Webhook handlers | 6 gateways | 6 gateways + custom | 6 + custom |
| Admin dashboard | basic JSON | rich (Next.js) | white-labelled |
| Multi-tenant mode | — | ✓ | ✓ |
| Setup support window | 30 days | 90 days | 12 months |
| SLA response | best-effort | 24h | 4h |
| Custom adapter development | per quote | included up to 8h | included up to 40h |
| On-call hours | — | — | 4h/month |
| Onboarding | docs only | 1h call | full migration plan |

## Why buyers buy

**Buyer persona**: small SaaS / B2B company with 10–500 monthly transactions, no in-house payments engineer.

Their alternatives:

1. **Build it themselves**: 6–12 weeks of senior dev time = $30k–$120k.
2. **Hire a consultancy**: $40k+ retainer over 3 months.
3. **Stripe-only without webhooks**: works until first failed payment, then loses revenue.
4. **Buy this bundle**: $499–$2,499 + ~1 day of integration.

The bundle is 5–50× cheaper than building or buying labor, with a working result in days not months.

## Distribution

- **Direct outreach**: LinkedIn + cold email to MENA SaaS founders (50/week sustainable).
- **Inbound from pub.dev**: the open-source package surfaces high-intent buyers.
- **Marketing site landing**: `marketing-site/backend-bundle` with calculator showing TCO vs build-it-yourself.
- **Referrals**: pay agencies 20% commission for sourcing customers.

## Conversion targets (year 1, conservative)

| Tier | Inquiries | Conversion | Customers | Revenue |
|---|---|---|---|---|
| Self-Hosted | 40 | 25% | 10 | $4,990 |
| Pro | 15 | 33% | 5 | $7,495 |
| Enterprise | 4 | 25% | 1 | $5,000 (mid-tier) |
| Managed Hosting | 5 | 40% | 2 | $200 × 12 + $400 × 12 = $7,200 ARR |
| **Total** | | | **18 + 2 ARR** | **~$24,685** year 1 |

## Support load

Higher than Model B but with higher margin:

- Self-Hosted: ~2h average over 30 days.
- Pro: ~6h over 90 days.
- Enterprise: ~30h over 12 months.

10 × 2h + 5 × 6h + 1 × 30h = **80h/year**. At a $50/h labor cost = $4,000. Profit margin: ~84% on Model C.

## Managed hosting margins

The $200–$500/month tier hosts the backend on Hetzner ($20/mo) plus monitoring ($10/mo) plus support time (~2h/mo). Per-customer cost basis: ~$130/mo. Margin: 35%–74% depending on tier price.

## Upsells

- Self-Hosted → Pro: pay difference + new tier of support ($1,000).
- Pro → Enterprise: pay difference + sign annual contract.
- Any tier → Managed Hosting: add $200–$500/mo.

## Risks

- **Concentration risk**: one enterprise customer can dominate revenue and absorb support hours. Mitigate by capping enterprise hours per quarter.
- **Webhook reliability**: any downtime in our backend = the customer's checkout breaks. Multi-region deploy from day 1 for Pro+.
- **Gateway breaking changes**: a Stripe / Paymob API breakage is on us to fix within the SLA. Maintain a 2-week buffer in support hours per quarter.
