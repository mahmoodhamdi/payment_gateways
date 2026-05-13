import { describe, expect, it } from 'vitest';

import { InMemoryTransactionStore } from '../src/db/transactions.js';

describe('InMemoryTransactionStore', () => {
  const init = {
    gatewayId: 'stripe',
    gatewayIntentId: 'pi_abc',
    amountMinorUnits: 4999,
    currency: 'USD',
    customerId: 'cust_1',
    status: 'pending' as const,
  };

  it('create assigns id + timestamps', async () => {
    const store = new InMemoryTransactionStore();
    const row = await store.create(init);
    expect(row.id).toBeTruthy();
    expect(row.createdAt).toBeGreaterThan(0);
    expect(row.updatedAt).toBeGreaterThan(0);
  });

  it('get returns the row', async () => {
    const store = new InMemoryTransactionStore();
    const row = await store.create(init);
    const fetched = await store.get(row.id);
    expect(fetched?.gatewayIntentId).toBe('pi_abc');
  });

  it('getByGatewayId looks up by (gateway, intent)', async () => {
    const store = new InMemoryTransactionStore();
    await store.create(init);
    const fetched = await store.getByGatewayId('stripe', 'pi_abc');
    expect(fetched).toBeDefined();
    const miss = await store.getByGatewayId('paymob', 'pi_abc');
    expect(miss).toBeUndefined();
  });

  it('setStatus updates the row and bumps updatedAt', async () => {
    const store = new InMemoryTransactionStore();
    const row = await store.create(init);
    const beforeUpdate = row.updatedAt;
    await new Promise((resolve) => setTimeout(resolve, 2));
    await store.setStatus(row.id, 'succeeded');
    const after = await store.get(row.id);
    expect(after?.status).toBe('succeeded');
    expect(after?.updatedAt).toBeGreaterThan(beforeUpdate);
  });

  it('list filters by gateway and status', async () => {
    const store = new InMemoryTransactionStore();
    await store.create(init);
    await store.create({ ...init, gatewayId: 'paymob' });
    const succeeded = await store.create({ ...init, status: 'succeeded' });
    expect(succeeded.status).toBe('succeeded');

    const stripeOnly = await store.list({ gatewayId: 'stripe' });
    expect(stripeOnly.length).toBe(2);
    const succeededOnly = await store.list({ status: 'succeeded' });
    expect(succeededOnly.length).toBe(1);
  });
});
