import { Router } from 'express';
import { z } from 'zod';

import { getGateway } from '../gateways/registry.js';
import { ApiError } from '../middleware/error_handler.js';

import type { TransactionStore } from '../db/transactions.js';

const refundBody = z.object({
  gateway_id: z.string(),
  transaction_id: z.string(),
  amount_minor_units: z.number().int().positive().optional(),
});

export function refundsRouter(store: TransactionStore): Router {
  const router = Router();

  router.post('/refunds', async (req, res, next) => {
    try {
      const parsed = refundBody.parse(req.body);
      const gateway = getGateway(parsed.gateway_id);
      if (!gateway || !gateway.isAvailable()) {
        throw new ApiError(
          400,
          'gateway_unavailable',
          `Gateway "${parsed.gateway_id}" is not configured.`,
        );
      }
      const ok = await gateway.refund(
        parsed.transaction_id,
        parsed.amount_minor_units,
      );
      if (ok) {
        const row = await store.getByGatewayId(
          gateway.id,
          parsed.transaction_id,
        );
        if (row) await store.setStatus(row.id, 'refunded');
      }
      res.json({ refunded: ok });
    } catch (e) {
      next(e);
    }
  });

  return router;
}
