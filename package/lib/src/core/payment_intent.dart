import 'package:meta/meta.dart';
import 'package:payment_gateways/src/core/currency.dart';
import 'package:payment_gateways/src/core/customer.dart';
import 'package:payment_gateways/src/core/money.dart';
import 'package:payment_gateways/src/core/order_metadata.dart';
import 'package:payment_gateways/src/core/payment_status.dart';

/// A payment intent is the in-progress representation of a checkout attempt.
///
/// Created by your application (with a gateway-issued `id` from a server-side
/// create call), then handed to a gateway adapter to progress.
@immutable
class PaymentIntent {
  const PaymentIntent({
    required this.id,
    required this.amountMinorUnits,
    required this.currency,
    required this.customer,
    this.metadata,
    this.status = PaymentStatus.pending,
    this.gatewayIntentId,
    this.gatewayName,
    this.clientSecret,
  });

  /// Your application's id for this intent. Use a strong unique value (UUIDv4
  /// or your own ULID); this id should not be guessable.
  final String id;

  /// Amount in the [currency]'s minor unit (cents, piastres, fils, ...).
  final int amountMinorUnits;

  /// ISO 4217 currency for this payment.
  final Currency currency;

  /// The customer paying.
  final Customer customer;

  /// Optional order metadata.
  final OrderMetadata? metadata;

  /// Current status as known to the SDK.
  final PaymentStatus status;

  /// Gateway-issued intent identifier (set after adapter creates the intent
  /// on the gateway side, either directly or through your backend).
  final String? gatewayIntentId;

  /// Which gateway is processing this intent ("stripe", "paymob", ...).
  final String? gatewayName;

  /// Gateway-specific client secret / payment key, when applicable. Never
  /// log or persist this to disk in plaintext.
  final String? clientSecret;

  /// Convenience: wrap as a [Money] value.
  Money get amount =>
      Money(amountMinorUnits: amountMinorUnits, currency: currency);

  PaymentIntent copyWith({
    String? id,
    int? amountMinorUnits,
    Currency? currency,
    Customer? customer,
    OrderMetadata? metadata,
    PaymentStatus? status,
    String? gatewayIntentId,
    String? gatewayName,
    String? clientSecret,
  }) {
    return PaymentIntent(
      id: id ?? this.id,
      amountMinorUnits: amountMinorUnits ?? this.amountMinorUnits,
      currency: currency ?? this.currency,
      customer: customer ?? this.customer,
      metadata: metadata ?? this.metadata,
      status: status ?? this.status,
      gatewayIntentId: gatewayIntentId ?? this.gatewayIntentId,
      gatewayName: gatewayName ?? this.gatewayName,
      clientSecret: clientSecret ?? this.clientSecret,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount_minor_units': amountMinorUnits,
        'currency': currency.code,
        'customer': customer.toJson(),
        if (metadata != null) 'metadata': metadata!.toJson(),
        'status': status.name,
        if (gatewayIntentId != null) 'gateway_intent_id': gatewayIntentId,
        if (gatewayName != null) 'gateway_name': gatewayName,
        // clientSecret deliberately omitted from JSON — must stay in-memory.
      };

  factory PaymentIntent.fromJson(Map<String, dynamic> json) {
    return PaymentIntent(
      id: json['id'] as String,
      amountMinorUnits: json['amount_minor_units'] as int,
      currency: Currency.parse(json['currency'] as String),
      customer: Customer.fromJson(json['customer'] as Map<String, dynamic>),
      metadata: json['metadata'] != null
          ? OrderMetadata.fromJson(json['metadata'] as Map<String, dynamic>)
          : null,
      status: PaymentStatus.values.firstWhere(
        (s) => s.name == (json['status'] as String? ?? 'pending'),
        orElse: () => PaymentStatus.pending,
      ),
      gatewayIntentId: json['gateway_intent_id'] as String?,
      gatewayName: json['gateway_name'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PaymentIntent &&
      other.id == id &&
      other.amountMinorUnits == amountMinorUnits &&
      other.currency == currency &&
      other.customer == customer &&
      other.metadata == metadata &&
      other.status == status &&
      other.gatewayIntentId == gatewayIntentId &&
      other.gatewayName == gatewayName;

  // clientSecret intentionally excluded from hash & equality — equality on
  // intents is logical (same business order), not "same in-memory secret".
  @override
  int get hashCode => Object.hash(
        id,
        amountMinorUnits,
        currency,
        customer,
        metadata,
        status,
        gatewayIntentId,
        gatewayName,
      );

  @override
  String toString() =>
      'PaymentIntent(id: $id, $amountMinorUnits ${currency.code}, '
      'status: $status)';
}
