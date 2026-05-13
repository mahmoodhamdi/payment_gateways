import { describe, expect, it } from 'vitest';

import { InMemoryIdempotencyStore } from '../src/lib/idempotency.js';

describe('InMemoryIdempotencyStore', () => {
  it('returns false on first sight, true on repeat', async () => {
    const s = new InMemoryIdempotencyStore();
    expect(await s.seen('stripe', 'evt_1')).toBe(false);
    expect(await s.seen('stripe', 'evt_1')).toBe(true);
  });

  it('keys are scoped per gateway', async () => {
    const s = new InMemoryIdempotencyStore();
    expect(await s.seen('stripe', 'evt_1')).toBe(false);
    expect(await s.seen('paymob', 'evt_1')).toBe(false);
    expect(await s.seen('stripe', 'evt_1')).toBe(true);
  });

  it('clear empties the store', async () => {
    const s = new InMemoryIdempotencyStore();
    await s.seen('stripe', 'evt_1');
    await s.clear();
    expect(await s.seen('stripe', 'evt_1')).toBe(false);
  });
});
