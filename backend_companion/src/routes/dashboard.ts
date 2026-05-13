import { Router } from 'express';

import type { TransactionStore } from '../db/transactions.js';

export function dashboardRouter(store: TransactionStore): Router {
  const router = Router();

  router.get('/dashboard/transactions', async (req, res, next) => {
    try {
      const gatewayId = req.query.gateway_id as string | undefined;
      const status = req.query.status as
        | 'pending'
        | 'succeeded'
        | 'failed'
        | 'refunded'
        | undefined;
      const rows = await store.list({ gatewayId, status });
      res.json({ count: rows.length, transactions: rows });
    } catch (e) {
      next(e);
    }
  });

  router.get('/dashboard/analytics', async (_req, res, next) => {
    try {
      const all = await store.list();
      const total = all.length;
      const byStatus = all.reduce<Record<string, number>>((acc, r) => {
        acc[r.status] = (acc[r.status] ?? 0) + 1;
        return acc;
      }, {});
      const byGateway = all.reduce<
        Record<string, { count: number; revenueMinor: number }>
      >((acc, r) => {
        const slot = acc[r.gatewayId] ?? { count: 0, revenueMinor: 0 };
        slot.count += 1;
        if (r.status === 'succeeded') slot.revenueMinor += r.amountMinorUnits;
        acc[r.gatewayId] = slot;
        return acc;
      }, {});
      const successCount = byStatus.succeeded ?? 0;
      const successRate = total === 0 ? 0 : successCount / total;
      res.json({
        total_transactions: total,
        success_rate: successRate,
        by_status: byStatus,
        by_gateway: byGateway,
      });
    } catch (e) {
      next(e);
    }
  });

  return router;
}
