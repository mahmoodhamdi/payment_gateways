import 'package:meta/meta.dart';
import 'package:payment_gateways/src/core/address.dart';

/// The customer making a payment. `id` is your application's own identifier;
/// the gateway-side customer identifier (if any) is managed by adapters.
@immutable
class Customer {
  const Customer({
    required this.id,
    this.email,
    this.phone,
    this.firstName,
    this.lastName,
    this.billingAddress,
    this.shippingAddress,
  });

  final String id;
  final String? email;
  final String? phone;
  final String? firstName;
  final String? lastName;
  final Address? billingAddress;
  final Address? shippingAddress;

  String get displayName {
    final parts = [firstName, lastName].whereType<String>().toList();
    if (parts.isEmpty) return email ?? id;
    return parts.join(' ');
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
        if (billingAddress != null) 'billing_address': billingAddress!.toJson(),
        if (shippingAddress != null)
          'shipping_address': shippingAddress!.toJson(),
      };

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      billingAddress: json['billing_address'] != null
          ? Address.fromJson(
              json['billing_address'] as Map<String, dynamic>,
            )
          : null,
      shippingAddress: json['shipping_address'] != null
          ? Address.fromJson(
              json['shipping_address'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Customer copyWith({
    String? id,
    String? email,
    String? phone,
    String? firstName,
    String? lastName,
    Address? billingAddress,
    Address? shippingAddress,
  }) {
    return Customer(
      id: id ?? this.id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      billingAddress: billingAddress ?? this.billingAddress,
      shippingAddress: shippingAddress ?? this.shippingAddress,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Customer &&
      other.id == id &&
      other.email == email &&
      other.phone == phone &&
      other.firstName == firstName &&
      other.lastName == lastName &&
      other.billingAddress == billingAddress &&
      other.shippingAddress == shippingAddress;

  @override
  int get hashCode => Object.hash(
        id,
        email,
        phone,
        firstName,
        lastName,
        billingAddress,
        shippingAddress,
      );

  @override
  String toString() => 'Customer(id: $id, email: $email)';
}
