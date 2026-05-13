import { Router } from 'express';

import { ApiError } from '../middleware/error_handler.js';

import type { TransactionStore } from '../db/transactions.js';

export function transactionsRouter(store: TransactionStore): Router {
  const router = Router();

  router.get('/transactions/:id', async (req, res, next) => {
    try {
      const row = await store.get(req.params.id);
      if (!row) {
        throw new ApiError(404, 'not_found', 'transaction not found');
      }
      res.json({
        transaction_id: row.id,
        gateway_id: row.gatewayId,
        gateway_intent_id: row.gatewayIntentId,
        status: row.status,
        amount_minor_units: row.amountMinorUnits,
        currency: row.currency,
        created_at: row.createdAt,
        updated_at: row.updatedAt,
      });
    } catch (e) {
      next(e);
    }
  });

  return router;
}
