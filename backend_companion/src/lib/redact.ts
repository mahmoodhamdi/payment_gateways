/**
 * Field names that must NEVER appear in logs unredacted. Mirrors the Flutter
 * package's redact() utility so the contract is identical on both sides.
 */
export const SENSITIVE_FIELD_NAMES = new Set<string>([
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
]);

export function redact(input: unknown): unknown {
  if (input === null || typeof input !== 'object') return input;
  if (Array.isArray(input)) return input.map((v) => redact(v));
  const out: Record<string, unknown> = {};
  for (const [k, v] of Object.entries(input as Record<string, unknown>)) {
    if (SENSITIVE_FIELD_NAMES.has(k.toLowerCase())) {
      out[k] = '***';
    } else if (v && typeof v === 'object') {
      out[k] = redact(v);
    } else {
      out[k] = v;
    }
  }
  return out;
}

export function maskValue(value: string): string {
  if (value.length <= 4) return '***';
  return '*'.repeat(value.length - 4) + value.slice(-4);
}
