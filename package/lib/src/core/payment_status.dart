/// Status of a payment as known to this SDK.
///
/// The gateway is the authoritative source of truth — this enum reflects the
/// SDK's view after the latest known event (success callback, webhook, or
/// poll).
enum PaymentStatus {
  /// Payment intent created, no further action taken yet.
  pending,

  /// SDK is in the middle of a checkout flow (e.g. waiting for 3DS).
  processing,

  /// 3-D Secure authentication required. Client must open the action URL.
  requires3ds,

  /// Customer must take action elsewhere (e.g. pay in cash at a Fawry outlet).
  requiresExternalAction,

  /// Payment confirmed by the gateway.
  succeeded,

  /// Payment attempted and rejected.
  failed,

  /// Customer canceled the flow before confirmation.
  canceled,

  /// Payment was succeeded then refunded (fully or partially).
  refunded;

  bool get isTerminal => switch (this) {
        succeeded || failed || canceled || refunded => true,
        _ => false,
      };

  bool get isInFlight => switch (this) {
        pending ||
        processing ||
        requires3ds ||
        requiresExternalAction =>
          true,
        _ => false,
      };
}
