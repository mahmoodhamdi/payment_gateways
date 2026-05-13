# Paymob — Setup Guide

Paymob is the primary card + wallet gateway for the Egyptian market and the strongest argument for using `payment_gateways` over `flutter_stripe` in MENA apps.

## 1. Get credentials

1. Sign up at [https://accept.paymob.com](https://accept.paymob.com) (production) or [https://accept.paymobsolutions.com](https://accept.paymobsolutions.com) (test mode).
2. Email integration@paymob.com to enable the merchant account.
3. From the dashboard:
   - **Developers → API Key**: copy the long base64-like string.
   - **Developers → Settings → Iframes**: create an iframe; copy the `iframe_id`.
   - **Developers → Settings → Integration IDs**: create integration IDs for each accepted method:
     - "Online Card Payment" → `PAYMOB_INTEGRATION_ID_CARD`.
     - "Mobile Wallet" (Vodafone Cash, Orange Cash, Etisalat Cash) → `PAYMOB_INTEGRATION_ID_WALLET`.
   - **Developers → Webhooks**: copy the **HMAC secret**.

## 2. Configure the backend

```bash
PAYMOB_API_KEY=...                # long base64 string
PAYMOB_HMAC_SECRET=...
PAYMOB_IFRAME_ID=12345
PAYMOB_INTEGRATION_ID_CARD=12345
PAYMOB_INTEGRATION_ID_WALLET=67890
```

## 3. Configure the Flutter app

```dart
'paymob': GatewayConfig.paymob(
  publicKey: '', // Paymob does not currently expose a client-side public key
  integrationIds: {
    'card': 12345,
    'mobile_wallet': 67890,
  },
  iframeId: '12345',
),
```

Add `PaymobGateway.builder` to your `gatewayBuilders` list.

## 4. Test mode

- Test cards from Paymob:
  - `5123 4567 8901 2346` (Mastercard, success)
  - `4111 1111 1111 1111` (Visa, success)
  - `5111 1111 1111 1118` (Mastercard, decline)
- Test wallet: phone `01010101010` with PIN `123456`.

## 5. The flow

1. App calls `PaymentGateways.checkout` with `PaymentMethod.card()` (or `.wallet(type: WalletType.vodafoneCash)`).
2. Adapter requests `/api/checkout` from the backend.
3. Backend executes Paymob's 3-step auth (auth_token → order → payment_key) and returns the iframe URL in `client_secret`.
4. Adapter opens the iframe URL in `ThreeDSWebView`.
5. Customer enters card details on Paymob's hosted page (PCI scope reduction: card data never enters your app).
6. On submit, Paymob redirects to one of:
   - `https://payment-gateways.local/paymob/success` → adapter resolves `PaymentSuccess`.
   - `https://payment-gateways.local/paymob/failure` → adapter resolves `PaymentFailure(CardDeclinedError)`.
7. Paymob webhook POSTs to `/webhooks/paymob` with the authoritative settlement event. The backend updates the transaction row to `succeeded` / `failed`.

## 6. Webhook configuration

In the Paymob dashboard, set the webhook URL to:

```
https://your-backend.example.com/webhooks/paymob
```

The backend verifies the HMAC signature using `PAYMOB_HMAC_SECRET`.

## 7. Mobile wallet flow

Wallet payments use the same iframe URL pattern but with the wallet integration ID instead of the card one. The customer enters their wallet phone number; Paymob sends an OTP; the user confirms; the iframe redirects.

## 8. Going to production

- [ ] Switch to the production Paymob URL (`accept.paymob.com`).
- [ ] Verify your KYC documents are approved.
- [ ] Update `PAYMOB_IFRAME_ID` and the integration IDs to the **production** values.
- [ ] Update the webhook URL on the production dashboard.
- [ ] Test a 1 EGP live transaction before launch.

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| `Paymob did not return a reference number` | Wrong `PAYMOB_API_KEY` or expired authentication token. |
| Webhook signature mismatch | Backend `PAYMOB_HMAC_SECRET` doesn't match the dashboard value. |
| iframe shows "merchant not found" | `PAYMOB_IFRAME_ID` is for a different account. |
| Wallet flow always declines | Wrong integration ID; double-check which integration corresponds to "Mobile Wallet". |
