import 'package:meta/meta.dart';
import 'package:payment_gateways/src/core/region.dart';

/// A billing or shipping address. All fields except [country] are nullable so
/// the type can be reused across gateways with varying field requirements.
@immutable
class Address {
  const Address({
    required this.country,
    this.line1,
    this.line2,
    this.city,
    this.state,
    this.postalCode,
  });

  final Region country;
  final String? line1;
  final String? line2;
  final String? city;
  final String? state;
  final String? postalCode;

  Map<String, dynamic> toJson() => {
        'country': country.code,
        if (line1 != null) 'line1': line1,
        if (line2 != null) 'line2': line2,
        if (city != null) 'city': city,
        if (state != null) 'state': state,
        if (postalCode != null) 'postal_code': postalCode,
      };

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      country: Region.parse(json['country'] as String),
      line1: json['line1'] as String?,
      line2: json['line2'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      postalCode: json['postal_code'] as String?,
    );
  }

  Address copyWith({
    Region? country,
    String? line1,
    String? line2,
    String? city,
    String? state,
    String? postalCode,
  }) {
    return Address(
      country: country ?? this.country,
      line1: line1 ?? this.line1,
      line2: line2 ?? this.line2,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Address &&
      other.country == country &&
      other.line1 == line1 &&
      other.line2 == line2 &&
      other.city == city &&
      other.state == state &&
      other.postalCode == postalCode;

  @override
  int get hashCode =>
      Object.hash(country, line1, line2, city, state, postalCode);

  @override
  String toString() =>
      'Address(country: $country, city: $city, postalCode: $postalCode)';
}
