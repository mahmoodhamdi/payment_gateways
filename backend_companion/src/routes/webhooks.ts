import { Router, raw } from 'express';

import { getGateway } from '../gateways/registry.js';
import type { IdempotencyStore } from '../lib/idempotency.js';
import { logger } from '../lib/logger.js';
import { ApiError } from '../middleware/error_handler.js';

import type { PaymentStatus, TransactionStore } from '../db/transactions.js';

/**
 * Webhook router. One endpoint per gateway, each:
 *   1. Reads the raw body (no JSON parsing before signature check).
 *   2. Verifies the signature via the gateway adapter.
 *   3. Idempotency-checks the event id.
 *   4. Applies the status update to the transaction store.
 *   5. Returns 200 immediately (no work past the ack).
 */
export function webhooksRouter(
  store: TransactionStore,
  idempotency: IdempotencyStore,
): Router {
  const router = Router();

  const gatewayIds = ['stripe', 'paymob', 'paytabs', 'fawry', 'paypal', 'square'];
  for (const gatewayId of gatewayIds) {
    router.post(
      `/webhooks/${gatewayId}`,
      raw({ type: '*/*', limit: '1mb' }),
      async (req, res, next) => {
        try {
          const gateway = getGateway(gatewayId);
          if (!gateway || !gateway.isAvailable()) {
            throw new ApiError(404, 'webhook_disabled');
          }
          const rawBody = req.body as Buffer;
          if (!gateway.verifyWebhookSignature(rawBody, req.headers)) {
            logger.warn({ gatewayId }, 'invalid webhook signature');
            throw new ApiError(401, 'invalid_signature');
          }
          const event = gateway.parseWebhookEvent(rawBody);
          const duplicate = await idempotency.seen(gatewayId, event.eventId);
          if (duplicate) {
            logger.info(
              { gatewayId, eventId: event.eventId },
              'duplicate webhook short-circuited',
            );
            res.status(200).json({ ok: true, duplicate: true });
            return;
          }

          // Apply status update if the event maps cleanly.
          const status = inferStatusFromEvent(gatewayId, event.type);
          if (status) {
            const row = await store.getByGatewayId(gatewayId, event.eventId);
            if (row) {
              await store.setStatus(row.id, status, event.data);
            }
          }

          res.status(200).json({ ok: true });
        } catch (e) {
          next(e);
        }
      },
    );
  }

  return router;
}

function inferStatusFromEvent(gatewayId: string, type: string): PaymentStatus | undefined {
  switch (gatewayId) {
    case 'stripe':
      if (type === 'payment_intent.succeeded') return 'succeeded';
      if (type === 'payment_intent.payment_failed') return 'failed';
      if (type === 'charge.refunded') return 'refunded';
      return undefined;
    case 'paymob':
      if (type === 'paymob.transaction.succeeded') return 'succeeded';
      if (type === 'paymob.transaction.failed') return 'failed';
      return undefined;
    case 'fawry':
      if (type.endsWith('.paid')) return 'succeeded';
      if (type.endsWith('.expired') || type.endsWith('.cancelled')) {
        return 'canceled';
      }
      return undefined;
    case 'paypal':
      if (type === 'CHECKOUT.ORDER.COMPLETED') return 'succeeded';
      if (type === 'PAYMENT.CAPTURE.DENIED') return 'failed';
      return undefined;
    case 'paytabs':
      if (type.toLowerCase().includes('a')) return 'succeeded'; // A=Authorised
      if (type.toLowerCase().includes('h')) return 'pending'; // H=Hold
      if (type.toLowerCase().includes('e')) return 'failed'; // E=Error
      return undefined;
    case 'square':
      if (type === 'payment.updated') return 'succeeded';
      return undefined;
  }
  return undefined;
}
