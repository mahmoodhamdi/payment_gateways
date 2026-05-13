import { describe, expect, it } from 'vitest';

import { maskValue, redact } from '../src/lib/redact.js';

describe('redact', () => {
  it('masks known sensitive keys', () => {
    const masked = redact({
      card_number: '4242 4242 4242 4242',
      cvv: '123',
      expiry: '12/29',
      safe: 'hello',
    }) as Record<string, unknown>;
    expect(masked.card_number).toBe('***');
    expect(masked.cvv).toBe('***');
    expect(masked.expiry).toBe('***');
    expect(masked.safe).toBe('hello');
  });

  it('recurses into nested objects', () => {
    const masked = redact({
      customer: { email: 'a@b.com', cvv: '999' },
    }) as Record<string, unknown>;
    const cust = masked.customer as Record<string, unknown>;
    expect(cust.email).toBe('a@b.com');
    expect(cust.cvv).toBe('***');
  });

  it('recurses into objects inside arrays', () => {
    const masked = redact({
      events: [{ pan: '4242', ok: 'fine' }],
    }) as Record<string, unknown>;
    const events = masked.events as Array<Record<string, unknown>>;
    expect(events[0].pan).toBe('***');
    expect(events[0].ok).toBe('fine');
  });

  it('is case-insensitive on keys', () => {
    const masked = redact({ PAN: '1234', Cvv: '999' }) as Record<string, unknown>;
    expect(masked.PAN).toBe('***');
    expect(masked.Cvv).toBe('***');
  });

  it('returns primitives unchanged', () => {
    expect(redact(42)).toBe(42);
    expect(redact('hello')).toBe('hello');
    expect(redact(null)).toBeNull();
    expect(redact(undefined)).toBeUndefined();
  });
});

describe('maskValue', () => {
  it('keeps last 4 chars when long enough', () => {
    expect(maskValue('4242424242424242')).toBe('************4242');
  });
  it('fully masks short values', () => {
    expect(maskValue('abc')).toBe('***');
  });
});
