/**
 * Idempotency store for webhook events. Stores `(gateway, event_id)` tuples
 * we've already processed so we ignore duplicate deliveries.
 *
 * v0.1 uses an in-memory Map. Production deployments should swap this for
 * Redis (set EX) or a DB unique constraint. The API mirrors that exact
 * future replacement: `seen()` returns true if the key existed before.
 */
export interface IdempotencyStore {
  seen(gateway: string, eventId: string): Promise<boolean>;
  clear(): Promise<void>;
}

export class InMemoryIdempotencyStore implements IdempotencyStore {
  private readonly seenIds = new Map<string, number>(); // key → unix ms inserted
  private readonly ttlMs = 1000 * 60 * 60 * 24 * 7; // 7 days

  async seen(gateway: string, eventId: string): Promise<boolean> {
    this.evictExpired();
    const key = `${gateway}:${eventId}`;
    if (this.seenIds.has(key)) return true;
    this.seenIds.set(key, Date.now());
    return false;
  }

  async clear(): Promise<void> {
    this.seenIds.clear();
  }

  private evictExpired(): void {
    const cutoff = Date.now() - this.ttlMs;
    for (const [k, inserted] of this.seenIds) {
      if (inserted < cutoff) this.seenIds.delete(k);
    }
  }
}
