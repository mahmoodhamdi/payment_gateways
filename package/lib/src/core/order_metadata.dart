import 'package:meta/meta.dart';

/// Optional structured metadata about the order behind a payment.
///
/// Stored alongside the payment intent and forwarded to the gateway when
/// supported. Useful for analytics, dispute resolution, and reconciliation.
@immutable
class OrderMetadata {
  const OrderMetadata({
    this.description,
    this.items = const [],
    this.referenceId,
    this.tags = const {},
  });

  final String? description;
  final List<OrderLineItem> items;
  final String? referenceId;
  final Map<String, String> tags;

  Map<String, dynamic> toJson() => {
        if (description != null) 'description': description,
        'items': items.map((i) => i.toJson()).toList(),
        if (referenceId != null) 'reference_id': referenceId,
        if (tags.isNotEmpty) 'tags': tags,
      };

  factory OrderMetadata.fromJson(Map<String, dynamic> json) {
    final itemsList = (json['items'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(OrderLineItem.fromJson)
        .toList();
    return OrderMetadata(
      description: json['description'] as String?,
      items: itemsList,
      referenceId: json['reference_id'] as String?,
      tags: (json['tags'] as Map<String, dynamic>? ?? const {})
          .map((k, v) => MapEntry(k, v.toString())),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is OrderMetadata &&
      other.description == description &&
      other.referenceId == referenceId &&
      _listEq(other.items, items) &&
      _mapEq(other.tags, tags);

  @override
  int get hashCode => Object.hash(
        description,
        referenceId,
        Object.hashAll(items),
        Object.hashAll(tags.entries.map((e) => Object.hash(e.key, e.value))),
      );

  @override
  String toString() =>
      'OrderMetadata(description: $description, items: ${items.length})';
}

/// A line item attached to an order.
@immutable
class OrderLineItem {
  const OrderLineItem({
    required this.name,
    required this.amountMinorUnits,
    this.quantity = 1,
    this.sku,
    this.description,
  });

  final String name;
  final int amountMinorUnits;
  final int quantity;
  final String? sku;
  final String? description;

  int get lineTotalMinorUnits => amountMinorUnits * quantity;

  Map<String, dynamic> toJson() => {
        'name': name,
        'amount_minor_units': amountMinorUnits,
        'quantity': quantity,
        if (sku != null) 'sku': sku,
        if (description != null) 'description': description,
      };

  factory OrderLineItem.fromJson(Map<String, dynamic> json) {
    return OrderLineItem(
      name: json['name'] as String,
      amountMinorUnits: json['amount_minor_units'] as int,
      quantity: json['quantity'] as int? ?? 1,
      sku: json['sku'] as String?,
      description: json['description'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is OrderLineItem &&
      other.name == name &&
      other.amountMinorUnits == amountMinorUnits &&
      other.quantity == quantity &&
      other.sku == sku &&
      other.description == description;

  @override
  int get hashCode =>
      Object.hash(name, amountMinorUnits, quantity, sku, description);

  @override
  String toString() =>
      'OrderLineItem($name x$quantity @ $amountMinorUnits minor units)';
}

bool _listEq<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _mapEq<K, V>(Map<K, V> a, Map<K, V> b) {
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (b[entry.key] != entry.value) return false;
  }
  return true;
}
