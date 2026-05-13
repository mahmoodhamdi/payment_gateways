/// Typed payment errors. Exhaustive in Dart 3 pattern matching:
///
/// ```dart
/// switch (error) {
///   case InsufficientFundsError(): // ...
///   case CardDeclinedError(:final reason): // ...
///   case ExpiredCardError(): // ...
///   case InvalidCvvError(): // ...
///   case ThreeDSecureFailedError(): // ...
///   case NetworkError(): // ...
///   case GatewayUnavailableError(:final gateway): // ...
///   case ConfigError(:final details): // ...
///   case UnknownError(): // ...
/// }
/// ```
sealed class PaymentError implements Exception {
  const PaymentError({this.gatewayCode, this.gatewayMessage});

  /// Raw gateway-issued error code (Stripe `card_declined`, Paymob `9999`, …).
  /// Carry it through for analytics, but display [userMessage] to end users.
  final String? gatewayCode;

  /// Raw gateway-issued message. Do NOT show directly — many gateways return
  /// messages that include PII or technical jargon. Use [userMessage] instead.
  final String? gatewayMessage;

  /// Code an analytics or logger should record (`insufficient_funds`,
  /// `card_declined`, ...). Maps 1:1 to a subclass.
  String get code;

  /// Localized, end-user-facing message. Defaults to English; integrators can
  /// override via the package's localization extension.
  String get userMessage;

  // Convenience factories.
  const factory PaymentError.insufficientFunds({String? gatewayCode}) =
      InsufficientFundsError;
  const factory PaymentError.cardDeclined({
    String? reason,
    String? gatewayCode,
  }) = CardDeclinedError;
  const factory PaymentError.expiredCard({String? gatewayCode}) =
      ExpiredCardError;
  const factory PaymentError.invalidCvv({String? gatewayCode}) =
      InvalidCvvError;
  const factory PaymentError.threeDSecureFailed({String? gatewayCode}) =
      ThreeDSecureFailedError;
  const factory PaymentError.network({String? gatewayMessage}) = NetworkError;
  const factory PaymentError.gatewayUnavailable({
    required String gateway,
    String? gatewayMessage,
  }) = GatewayUnavailableError;
  const factory PaymentError.misconfiguration({required String details}) =
      ConfigError;
  const factory PaymentError.unknown({
    Object? cause,
    String? gatewayCode,
    String? gatewayMessage,
  }) = UnknownError;
}

final class InsufficientFundsError extends PaymentError {
  const InsufficientFundsError({super.gatewayCode});
  @override
  String get code => 'insufficient_funds';
  @override
  String get userMessage =>
      'Your card does not have enough funds for this purchase.';
}

final class CardDeclinedError extends PaymentError {
  const CardDeclinedError({this.reason, super.gatewayCode});
  final String? reason;
  @override
  String get code => 'card_declined';
  @override
  String get userMessage =>
      'Your card was declined. Please try a different card.';
}

final class ExpiredCardError extends PaymentError {
  const ExpiredCardError({super.gatewayCode});
  @override
  String get code => 'expired_card';
  @override
  String get userMessage =>
      'Your card has expired. Please use another card.';
}

final class InvalidCvvError extends PaymentError {
  const InvalidCvvError({super.gatewayCode});
  @override
  String get code => 'invalid_cvv';
  @override
  String get userMessage =>
      'The security code you entered does not match. Please re-enter.';
}

final class ThreeDSecureFailedError extends PaymentError {
  const ThreeDSecureFailedError({super.gatewayCode});
  @override
  String get code => '3ds_failed';
  @override
  String get userMessage =>
      '3-D Secure authentication failed. Please try again or '
      'use a different card.';
}

final class NetworkError extends PaymentError {
  const NetworkError({super.gatewayMessage});
  @override
  String get code => 'network';
  @override
  String get userMessage =>
      'A network error occurred. Please check your connection and try again.';
}

final class GatewayUnavailableError extends PaymentError {
  const GatewayUnavailableError({
    required this.gateway,
    super.gatewayMessage,
  });
  final String gateway;
  @override
  String get code => 'gateway_unavailable';
  @override
  String get userMessage =>
      'The payment provider is temporarily unavailable. '
      'Please try again shortly.';
}

final class ConfigError extends PaymentError {
  const ConfigError({required this.details});
  final String details;
  @override
  String get code => 'misconfiguration';
  @override
  String get userMessage =>
      'Payments are unavailable due to a configuration issue. '
      'Please contact support.';
  @override
  String toString() => 'ConfigError: $details';
}

final class UnknownError extends PaymentError {
  const UnknownError({
    this.cause,
    super.gatewayCode,
    super.gatewayMessage,
  });
  final Object? cause;
  @override
  String get code => 'unknown';
  @override
  String get userMessage =>
      'An unexpected error occurred. Please try again.';
  @override
  String toString() =>
      'UnknownError(code: $gatewayCode, cause: $cause)';
}
