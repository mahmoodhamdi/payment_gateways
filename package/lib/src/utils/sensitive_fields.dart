/// Set of JSON / map field names that must never appear in logs.
///
/// Both the package's own logger and the backend companion's logger filter
/// these keys.
const Set<String> sensitiveFieldNames = {
  'pan',
  'card_number',
  'cardnumber',
  'number',
  'cc_number',
  'cvv',
  'cvc',
  'cvv2',
  'card_cvc',
  'card_cvv',
  'security_code',
  'expiry',
  'expiry_date',
  'exp_month',
  'exp_year',
  'card_holder',
  'cardholder',
  'cardholder_name',
  'secret',
  'secret_key',
  'sk',
  'api_secret',
  'access_token',
  'refresh_token',
  'bearer',
  'authorization',
  'auth_token',
  'session_token',
  'client_secret',
  'private_key',
  'password',
  'pin',
};

/// Mask a sensitive value for logging (keeps last 4 digits / chars).
String maskValue(String value) {
  if (value.length <= 4) return '***';
  return '${'*' * (value.length - 4)}${value.substring(value.length - 4)}';
}

/// Returns a deep copy of [map] with values for sensitive keys replaced by
/// `'***'`. Use before serializing structured logs.
Map<String, Object?> redact(Map<String, Object?> map) {
  final out = <String, Object?>{};
  for (final entry in map.entries) {
    if (sensitiveFieldNames.contains(entry.key.toLowerCase())) {
      out[entry.key] = '***';
      continue;
    }
    final value = entry.value;
    out[entry.key] = switch (value) {
      Map<String, Object?>() => redact(value),
      List<Object?>() => value.map((v) {
          return v is Map<String, Object?> ? redact(v) : v;
        }).toList(),
      _ => value,
    };
  }
  return out;
}
