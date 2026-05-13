# Customer Handover Checklist

Use this for every new Backend Bundle customer to ensure a clean handover and minimize support load downstream.

## Day 0 — Pre-kickoff

- [ ] Signed commercial license / quote acceptance.
- [ ] PO received (Enterprise) or Stripe payment confirmed (Self-Hosted / Pro).
- [ ] Customer's primary technical contact identified.
- [ ] Slack channel created (Pro+) with the customer invited.
- [ ] Customer's preferred deployment platform confirmed (Hetzner / DO / Railway / their own).
- [ ] Customer's target gateways confirmed (Stripe / Paymob / Fawry / PayTabs / PayPal / Square).
- [ ] Customer's expected transaction volume captured (informs SLA tier and hosting sizing).

## Week 1 — Setup

- [ ] Backend repo cloned / forked to customer's GitHub org.
- [ ] `.env.production` populated by customer (we provide template, they fill secrets).
- [ ] Gateway test-mode credentials verified working (1 EGP test charge through each gateway).
- [ ] Webhook URLs configured on each gateway's dashboard.
- [ ] HTTPS + valid TLS certificate confirmed on the customer's domain.
- [ ] First Dockerized deployment to the chosen platform.
- [ ] `/health` endpoint returns expected gateways.
- [ ] Smoke test: full end-to-end checkout via the template_app or customer's app.

## Week 2 — Production

- [ ] Live gateway credentials swapped in `.env.production`.
- [ ] 1 EGP (or smallest unit) live test charge per gateway.
- [ ] Webhook URLs swapped to live mode on each gateway.
- [ ] Monitoring / alerting configured (Grafana, Sentry, etc. — customer's choice).
- [ ] Backup / recovery plan documented.
- [ ] Customer's runbook for "checkout is down" updated.

## Week 3 — Handover

- [ ] Customer's team trained on the codebase (1h video call recorded).
- [ ] Customer reproduces a successful deploy from scratch without our help.
- [ ] Customer demonstrates webhook handling for at least one gateway.
- [ ] Customer demonstrates refund flow.
- [ ] Customer reads `docs/PCI_COMPLIANCE.md` and acknowledges scope.
- [ ] Customer has the right shared-key access for support escalations.

## Month 1 — Stabilization

- [ ] First weekly sync (Pro+) or scheduled check-in (Self-Hosted).
- [ ] Review log volume; tune log levels if needed.
- [ ] Review transaction volume vs sizing — upgrade hosting if approaching limits.
- [ ] Confirm no support issues outstanding.

## Month 2-3 — Maturity

- [ ] Move customer to monthly check-in cadence.
- [ ] Document any custom adapter work in customer's fork.
- [ ] Renew or upsell to a longer support tier as 90-day window closes.

## Red flags during handover

| Sign | Likely cause | Action |
|---|---|---|
| Customer can't get past `/health` returning gateways | Their secrets aren't loading; env file location wrong | Live debug session |
| Webhooks aren't reaching backend | DNS / firewall / IP allowlist | Trace from gateway's logs |
| First live charge fails | Test-mode credentials still active | Re-verify every env var |
| Customer asks about storing card numbers | Misunderstanding PCI scope | Point at `docs/PCI_COMPLIANCE.md` |
| Customer demands feature outside scope | Misaligned expectations from sale | Reset scope expectations; offer paid hours |

## Post-handover

- [ ] Internal: record total support hours spent on this customer (helps price future deals).
- [ ] Internal: capture any code we wrote that's reusable; merge upstream to `payment_gateways`.
- [ ] Internal: ask for testimonial / case study consent.
- [ ] Internal: schedule 30/60/90/180-day follow-ups.
