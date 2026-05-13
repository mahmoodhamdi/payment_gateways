import { Router } from 'express';
import { z } from 'zod';

import { getGateway } from '../gateways/registry.js';
import { logger } from '../lib/logger.js';
import { ApiError } from '../middleware/error_handler.js';

import type { TransactionStore } from '../db/transactions.js';

const createIntentBody = z.object({
  gateway_id: z.string(),
  intent: z.object({
    id: z.string(),
    amount_minor_units: z.number().int().positive(),
    currency: z.string().length(3),
    customer: z.object({
      id: z.string(),
      email: z.string().optional(),
      phone: z.string().optional(),
      first_name: z.string().optional(),
      last_name: z.string().optional(),
      billing_address: z.object({ country: z.string() }).optional(),
    }),
    metadata: z.record(z.unknown()).optional(),
  }),
});

const confirmCardBody = z.object({
  gateway_id: z.string(),
  gateway_intent_id: z.string(),
  card: z.object({
    number: z.string().regex(/^\d{13,19}$/),
    exp_month: z.number().int().min(1).max(12),
    exp_year: z.number().int().min(2026).max(2100),
    cvv: z.string().regex(/^\d{3,4}$/),
    cardholder_name: z.string().optional(),
  }),
  return_urls: z.object({
    success: z.string().url(),
    failure: z.string().url(),
  }),
});

export function checkoutRouter(store: TransactionStore): Router {
  const router = Router();

  router.post('/checkout', async (req, res, next) => {
    try {
      const parsed = createIntentBody.parse(req.body);
      const gateway = getGateway(parsed.gateway_id);
      if (!gateway || !gateway.isAvailable()) {
        throw new ApiError(
          400,
          'gateway_unavailable',
          `Gateway "${parsed.gateway_id}" is not configured on this server.`,
        );
      }
      const result = await gateway.createIntent(parsed);

      // Persist as a pending row so webhooks can find us by gatewayIntentId.
      await store.create({
        gatewayId: gateway.id,
        gatewayIntentId: result.gateway_intent_id,
        amountMinorUnits: parsed.intent.amount_minor_units,
        currency: parsed.intent.currency,
        customerId: parsed.intent.customer.id,
        status: result.status === 'requires3ds' ? 'requires3ds' : 'pending',
      });

      res.json({
        intent: { ...parsed.intent, status: result.status },
        gateway_intent_id: result.gateway_intent_id,
        client_secret: result.client_secret,
      });
    } catch (e) {
      next(e);
    }
  });

  router.post('/checkout/confirm', async (req, res, next) => {
    try {
      const parsed = confirmCardBody.parse(req.body);
      const gateway = getGateway(parsed.gateway_id);
      if (!gateway || !gateway.confirmCard) {
        throw new ApiError(
          400,
          'gateway_unavailable',
          `Gateway "${parsed.gateway_id}" cannot confirm card flows.`,
        );
      }
      logger.info(
        {
          gateway_id: parsed.gateway_id,
          gateway_intent_id: parsed.gateway_intent_id,
        },
        'Confirming card via backend (card data not persisted)',
      );
      const result = await gateway.confirmCard(parsed);

      if (result.transaction_id) {
        const row = await store.getByGatewayId(
          gateway.id,
          parsed.gateway_intent_id,
        );
        if (row) {
          await store.setStatus(
            row.id,
            result.status === 'succeeded'
              ? 'succeeded'
              : result.status === 'failed'
                ? 'failed'
                : 'requires3ds',
          );
        }
      }

      res.json(result);
    } catch (e) {
      next(e);
    }
  });

  return router;
}
