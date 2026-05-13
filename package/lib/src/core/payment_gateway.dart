import 'package:flutter/widgets.dart';
import 'package:payment_gateways/src/core/gateway_metadata.dart';
import 'package:payment_gateways/src/core/payment_intent.dart';
import 'package:payment_gateways/src/core/payment_method.dart';
import 'package:payment_gateways/src/core/payment_result.dart';
import 'package:payment_gateways/src/core/payment_status.dart';

/// Per-gateway adapter contract. Implementations live in
/// `package/lib/src/gateways/<gateway>/` and are registered with the
/// `PaymentRouter` at startup.
///
/// All methods must complete with one of the [PaymentResult] variants —
/// never let an exception bubble up to the caller. Wrap thrown errors as
/// `PaymentFailure(error: PaymentError.unknown(cause: …))`.
abstract interface class PaymentGateway {
  /// Stable id (`"stripe"`, `"paymob"`, ...). Must match
  /// `metadata.id`.
  String get id;

  /// Static descriptor.
  GatewayMetadata get metadata;

  /// Quick predicate used by the router and the UI to filter unsupported
  /// payment methods before constructing an intent.
  bool supports(PaymentMethod method);

  /// Run the checkout flow:
  /// 1. Tokenize / collect payment material (gateway-native UI or this
  ///    package's `CardInput` widget).
  /// 2. Confirm the intent (potentially via a 3DS WebView opened in
  ///    [context]).
  /// 3. Return a [PaymentResult].
  ///
  /// Adapters must NEVER attempt to bypass 3DS or other gateway
  /// authentication. Adapters must NEVER bundle secret API keys.
  Future<PaymentResult> initiate({
    required PaymentIntent intent,
    required PaymentMethod method,
    required BuildContext context,
  });

  /// Refund (full or partial) a previously successful transaction.
  /// Refunds must happen server-side; this method calls the backend
  /// companion which holds the secret key.
  Future<PaymentResult> refund({
    required String transactionId,
    int? amountMinorUnits,
  });

  /// Poll status for a pending payment. Used by the Fawry/cash flow,
  /// bank transfer reconciliation, etc.
  Future<PaymentStatus> getStatus({required String transactionId});
}
