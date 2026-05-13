# Security Policy

`payment_gateways` handles payment flows for live commerce. Security is therefore non-negotiable.

## Reporting a Vulnerability

If you discover a security vulnerability:

1. **Do not** open a public GitHub issue.
2. Email the maintainer privately via the address on the maintainer's GitHub profile, or open a private security advisory at https://github.com/mahmoodhamdi/payment_gateways/security/advisories/new.
3. Provide:
   - A description of the vulnerability and affected component (`package`, `template_app`, or `backend_companion`).
   - Step-by-step reproduction (PoC if possible).
   - Expected vs actual behavior.
   - Suggested fix, if available.

We will acknowledge receipt within 72 hours and aim to release a fix or mitigation within 14 days for critical issues.

## Supported Versions

| Version | Supported |
|---|---|
| `0.x` | Security fixes only (no new features) |
| latest stable | Full support |

## Threat Model (high-level)

This SDK is designed under the following hard constraints:

| Constraint | Why |
|---|---|
| **No raw PAN, CVV, or expiry in Flutter / Dart code paths** | PCI scope reduction. All sensitive data is captured in gateway-hosted iframes / native SDKs. |
| **No secret keys (Stripe `sk_`, Paymob `secret_key`, etc.) bundled in the client** | A `.apk` / `.ipa` is decompilable. Secrets are server-side only. |
| **All webhooks signature-verified server-side** | Replay attacks, forged status updates. |
| **HTTPS-only** | Every URL touched by the SDK must be `https://`. |
| **No payment data in logs** | The package's logger filters known sensitive field names: `pan`, `card_number`, `cvv`, `cvc`, `card_cvc`, `expiry`, `secret`, `token`. |
| **Idempotent webhooks** | Backend stores `(gateway, event_id)` uniqueness; duplicate webhook deliveries are short-circuited. |

## What the package does NOT do

- Store, transmit, or log raw card numbers.
- Accept secret API keys from the client.
- Bypass 3DS authentication when the gateway requires it.
- Trust webhook payloads without signature verification.

## Reporting test mode misuse

If you observe the SDK shipping with live keys hardcoded, or test fixtures committed that include real card numbers, please flag this as a security issue.

## Dependency management

- Dependencies are pinned to compatible-range versions in `pubspec.yaml` / `package.json`.
- `flutter pub outdated` and `npm audit` are part of the weekly CI.
- Dependabot is enabled for security patch updates.

## PCI-DSS scope

By using only tokenization flows and gateway-hosted iframes for raw card input, integrators of this SDK qualify for **SAQ A** (the simplest PCI-DSS self-assessment). The `docs/PCI_COMPLIANCE.md` document explains scope reduction in detail.
