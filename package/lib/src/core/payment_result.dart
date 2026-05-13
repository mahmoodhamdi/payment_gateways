import 'package:meta/meta.dart';
import 'package:payment_gateways/src/core/payment_error.dart';

/// The terminal (or near-terminal) outcome of a payment attempt.
///
/// Use Dart 3 pattern matching:
///
/// ```dart
/// switch (result) {
///   case PaymentSuccess(:final transactionId): // confirm order
///   case PaymentFailure(error: InsufficientFundsError()): // show specific msg
///   case PaymentFailure(:final error): // show generic
///   case PaymentCanceled(): // user backed out
///   case PaymentPendingAction(:final actionUrl): // open 3DS / Fawry ref
/// }
/// ```
@immutable
sealed class PaymentResult {
  const PaymentResult();

  const factory PaymentResult.success({
    required String transactionId,
    String? gatewayName,
    String? receiptUrl,
    Map<String, Object?>? raw,
  }) = PaymentSuccess;

  const factory PaymentResult.failure({
    required PaymentError error,
    String? transactionId,
  }) = PaymentFailure;

  const factory PaymentResult.canceled() = PaymentCanceled;

  const factory PaymentResult.pendingAction({
    required Uri actionUrl,
    String? transactionId,
    PendingActionType type,
    String? reference,
  }) = PaymentPendingAction;
}

final class PaymentSuccess extends PaymentResult {
  const PaymentSuccess({
    required this.transactionId,
    this.gatewayName,
    this.receiptUrl,
    this.raw,
  });

  /// Gateway-issued transaction id. Persist this for reconciliation.
  final String transactionId;

  /// Gateway that processed the payment ("stripe", "paymob", ...).
  final String? gatewayName;

  /// Public receipt URL (when gateway supports it).
  final String? receiptUrl;

  /// Raw gateway response payload. Useful for audit logs; do NOT trust
  /// untyped fields without re-parsing on the server side.
  final Map<String, Object?>? raw;

  @override
  bool operator ==(Object other) =>
      other is PaymentSuccess &&
      other.transactionId == transactionId &&
      other.gatewayName == gatewayName &&
      other.receiptUrl == receiptUrl;

  @override
  int get hashCode => Object.hash(transactionId, gatewayName, receiptUrl);

  @override
  String toString() =>
      'PaymentSuccess(txnId: $transactionId, gateway: $gatewayName)';
}

final class PaymentFailure extends PaymentResult {
  const PaymentFailure({required this.error, this.transactionId});

  final PaymentError error;
  final String? transactionId;

  @override
  bool operator ==(Object other) =>
      other is PaymentFailure &&
      other.error == error &&
      other.transactionId == transactionId;

  @override
  int get hashCode => Object.hash(error, transactionId);

  @override
  String toString() => 'PaymentFailure(${error.code}, txnId: $transactionId)';
}

final class PaymentCanceled extends PaymentResult {
  const PaymentCanceled();

  @override
  bool operator ==(Object other) => other is PaymentCanceled;

  @override
  int get hashCode => 'PaymentCanceled'.hashCode;

  @override
  String toString() => 'PaymentCanceled()';
}

final class PaymentPendingAction extends PaymentResult {
  const PaymentPendingAction({
    required this.actionUrl,
    this.transactionId,
    this.type = PendingActionType.threeDSecure,
    this.reference,
  });

  /// URL to open in a WebView (3DS challenge) or to show to the user
  /// (Fawry receipt, bank transfer instructions, etc.).
  final Uri actionUrl;

  /// Optional gateway-issued transaction id (may not exist yet at this stage).
  final String? transactionId;

  /// Kind of pending action.
  final PendingActionType type;

  /// Human-readable reference number for cash flows (Fawry, Aman).
  final String? reference;

  @override
  bool operator ==(Object other) =>
      other is PaymentPendingAction &&
      other.actionUrl == actionUrl &&
      other.transactionId == transactionId &&
      other.type == type &&
      other.reference == reference;

  @override
  int get hashCode =>
      Object.hash(actionUrl, transactionId, type, reference);

  @override
  String toString() =>
      'PaymentPendingAction($type, actionUrl: $actionUrl, ref: $reference)';
}

/// What the user is being asked to do during a pending action.
enum PendingActionType {
  threeDSecure,
  cashAtOutlet,
  bankTransfer,
  redirectToGateway,
}
