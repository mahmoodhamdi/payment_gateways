# payment_gateways

A unified Flutter SDK for integrating multiple payment gateways with first-class support for the MENA region.

[![Pub Version](https://img.shields.io/pub/v/payment_gateways.svg)](https://pub.dev/packages/payment_gateways)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## Why

Most Flutter payment packages wrap a single gateway. This package gives you a single API across **Stripe, Paymob, PayTabs, Fawry, PayPal, Square** — with consistent types, error handling, and webhook expectations regardless of which gateway you actually use.

For MENA developers, Paymob, Fawry, and PayTabs are first-class — not second-tier afterthoughts.

## Install

```yaml
dependencies:
  payment_gateways: ^0.1.0
```

```bash
flutter pub get
```

## Quick start

```dart
import 'package:payment_gateways/payment_gateways.dart';

// 1. Configure once, at app startup.
final gateways = PaymentGateways(
  config: PaymentConfig(
    environment: Environment.test,
    gateways: {
      'stripe':  GatewayConfig.stripe(publishableKey: 'pk_test_...'),
      'paymob':  GatewayConfig.paymob(publicKey: 'pk_...', integrationIds: {
        'card':        12345,
        'mobile_wallet': 67890,
      }),
    },
    routing: RoutingRules.byCountry(),
    backendBaseUrl: Uri.parse('https://api.your-app.com'),
  ),
);

// 2. At checkout time, hand the gateway an intent and a method.
final result = await gateways.checkout(
  intent: PaymentIntent(
    id: 'order-12345',
    amountMinorUnits: 4999,        // $49.99
    currency: 'USD',
    customer: Customer(
      id: 'user-1', email: 'alice@example.com', phone: '+201001234567',
    ),
  ),
  method: const PaymentMethod.card(),
  context: context,
);

// 3. Branch on the typed result.
switch (result) {
  case PaymentSuccess(transactionId: final id): // ...
  case PaymentFailure(error: InsufficientFunds()): // ...
  case PaymentFailure(error: CardDeclined()): // ...
  case PaymentPendingAction(actionUrl: final url): // 3DS
  case PaymentCanceled(): // ...
  case PaymentFailure(): // generic
}
```

## Important security notes

- **Never** put gateway **secret** API keys in your Flutter app. Only `publishableKey`-class material belongs here. Real payment intents must be created server-side — this package expects a `backendBaseUrl` for that.
- **All webhooks** must be received and verified server-side. The companion `backend_companion/` ships pre-wired handlers for every supported gateway.
- The package never stores card numbers or CVVs in plaintext, ever. Gateway-native tokenization is the only flow supported.

## Supported gateways

See the [top-level README](../README.md#supported-payment-gateways) for the gateway matrix.

## Per-gateway setup

- [Stripe](../docs/gateways/stripe.md)
- [Paymob](../docs/gateways/paymob.md)
- [PayTabs](../docs/gateways/paytabs.md)
- [Fawry](../docs/gateways/fawry.md)
- [PayPal](../docs/gateways/paypal.md)
- [Square](../docs/gateways/square.md)

## Recipes

- [One-time purchase](../docs/recipes/one_time_purchase.md)
- [Subscriptions](../docs/recipes/subscription_billing.md)
- [Marketplace payments](../docs/recipes/marketplace_payments.md)
- [Fawry cash-at-outlet](../docs/recipes/cash_on_delivery_fawry.md)
- [Arabic / RTL checkout](../docs/recipes/arabic_checkout_ui.md)
- [Multi-currency global](../docs/recipes/multi_currency_global.md)

## Testing

```bash
flutter test --coverage
```

## License

MIT — see [LICENSE](LICENSE).
