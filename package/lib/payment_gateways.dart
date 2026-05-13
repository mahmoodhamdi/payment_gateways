/// payment_gateways — a unified Flutter SDK for Stripe, Paymob, PayTabs,
/// Fawry, PayPal, Square (and more), with first-class support for the MENA
/// region.
///
/// Quick start:
///
/// ```dart
/// import 'package:payment_gateways/payment_gateways.dart';
///
/// final gateways = PaymentGateways(
///   config: PaymentConfig(
///     environment: Environment.test,
///     gateways: {
///       'stripe': GatewayConfig.stripe(publishableKey: 'pk_test_...'),
///     },
///     backendBaseUrl: Uri.parse('https://api.your-app.com'),
///   ),
///   gatewayBuilders: [
///     StripeGateway.builder,
///   ],
/// );
///
/// final result = await gateways.checkout(
///   intent: PaymentIntent(...),
///   method: const PaymentMethod.card(),
///   context: context,
/// );
/// ```
library payment_gateways;

export 'src/backend/backend_client.dart';
export 'src/core/address.dart';
export 'src/core/currency.dart';
export 'src/core/customer.dart';
export 'src/core/environment.dart';
export 'src/core/gateway_config.dart';
export 'src/core/gateway_metadata.dart';
export 'src/core/money.dart';
export 'src/core/order_metadata.dart';
export 'src/core/payment_config.dart';
export 'src/core/payment_error.dart';
export 'src/core/payment_gateway.dart';
export 'src/core/payment_intent.dart';
export 'src/core/payment_method.dart';
export 'src/core/payment_result.dart';
export 'src/core/payment_router.dart';
export 'src/core/payment_status.dart';
export 'src/core/region.dart';
export 'src/gateways/fawry/fawry_gateway.dart';
export 'src/gateways/paymob/paymob_gateway.dart';
export 'src/gateways/paypal/paypal_gateway.dart';
export 'src/gateways/paytabs/paytabs_gateway.dart';
export 'src/gateways/square/square_gateway.dart';
export 'src/gateways/stripe/stripe_gateway.dart';
export 'src/payment_gateways_facade.dart';
export 'src/ui/card_input.dart';
export 'src/ui/checkout_form.dart';
export 'src/ui/order_summary.dart';
export 'src/ui/payment_gateways_theme.dart';
export 'src/ui/payment_method_selector.dart';
export 'src/ui/payment_result_dialog.dart';
export 'src/ui/three_ds_webview.dart';
export 'src/ui/wallet_buttons.dart';
export 'src/utils/logger.dart' show LogLevel, LogSink, PaymentLogger;
export 'src/utils/sensitive_fields.dart' show maskValue, redact;
