import { randomUUID } from 'node:crypto';

export type PaymentStatus =
  | 'pending'
  | 'processing'
  | 'requires3ds'
  | 'requiresExternalAction'
  | 'succeeded'
  | 'failed'
  | 'canceled'
  | 'refunded';

export interface TransactionRecord {
  id: string;
  gatewayId: string;
  gatewayIntentId: string;
  amountMinorUnits: number;
  currency: string;
  customerId: string;
  status: PaymentStatus;
  createdAt: number;
  updatedAt: number;
  raw?: unknown;
}

export interface TransactionStore {
  create(
    init: Omit<TransactionRecord, 'id' | 'createdAt' | 'updatedAt'>,
  ): Promise<TransactionRecord>;
  get(id: string): Promise<TransactionRecord | undefined>;
  getByGatewayId(gatewayId: string, gatewayIntentId: string): Promise<TransactionRecord | undefined>;
  setStatus(id: string, status: PaymentStatus, raw?: unknown): Promise<void>;
  list(filter?: { gatewayId?: string; status?: PaymentStatus }): Promise<TransactionRecord[]>;
}

/**
 * In-memory store. Replace with MongoDB by implementing TransactionStore.
 */
export class InMemoryTransactionStore implements TransactionStore {
  private readonly rows = new Map<string, TransactionRecord>();

  async create(
    init: Omit<TransactionRecord, 'id' | 'createdAt' | 'updatedAt'>,
  ): Promise<TransactionRecord> {
    const now = Date.now();
    const row: TransactionRecord = {
      ...init,
      id: randomUUID(),
      createdAt: now,
      updatedAt: now,
    };
    this.rows.set(row.id, row);
    return row;
  }

  async get(id: string): Promise<TransactionRecord | undefined> {
    return this.rows.get(id);
  }

  async getByGatewayId(
    gatewayId: string,
    gatewayIntentId: string,
  ): Promise<TransactionRecord | undefined> {
    for (const row of this.rows.values()) {
      if (row.gatewayId === gatewayId && row.gatewayIntentId === gatewayIntentId) {
        return row;
      }
    }
    return undefined;
  }

  async setStatus(id: string, status: PaymentStatus, raw?: unknown): Promise<void> {
    const row = this.rows.get(id);
    if (!row) return;
    row.status = status;
    row.updatedAt = Date.now();
    if (raw !== undefined) row.raw = raw;
  }

  async list(filter: { gatewayId?: string; status?: PaymentStatus } = {}): Promise<TransactionRecord[]> {
    const all = Array.from(this.rows.values());
    return all.filter(
      (r) =>
        (filter.gatewayId === undefined || r.gatewayId === filter.gatewayId) &&
        (filter.status === undefined || r.status === filter.status),
    );
  }
}
