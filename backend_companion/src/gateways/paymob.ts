import { createHmac } from 'node:crypto';

import { loadEnv } from '../config.js';
import { logger } from '../lib/logger.js';
import type {
  CreateIntentInput,
  CreateIntentResult,
  GatewayAdapter,
} from './types.js';

const PAYMOB_BASE = 'https://accept.paymob.com/api';

/**
 * Server-side Paymob adapter.
 *
 * Flow:
 *  1. POST /auth/tokens               → auth_token
 *  2. POST /ecommerce/orders          → order id
 *  3. POST /acceptance/payment_keys   → payment_key (used to build iframe URL)
 *
 * Webhooks are HMAC-signed; we recompute and constant-time-compare.
 */
export class PaymobAdapter implements GatewayAdapter {
  readonly id = 'paymob';

  isAvailable(): boolean {
    const env = loadEnv();
    return !!(
      env.PAYMOB_API_KEY &&
      env.PAYMOB_HMAC_SECRET &&
      env.PAYMOB_IFRAME_ID
    );
  }

  async createIntent(input: CreateIntentInput): Promise<CreateIntentResult> {
    const env = loadEnv();
    if (!env.PAYMOB_API_KEY || !env.PAYMOB_IFRAME_ID) {
      throw new Error('Paymob is not configured');
    }
    const authRes = await fetch(`${PAYMOB_BASE}/auth/tokens`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ api_key: env.PAYMOB_API_KEY }),
    });
    if (!authRes.ok) {
      throw new Error(`Paymob auth failed: ${authRes.status}`);
    }
    const auth = (await authRes.json()) as { token: string };

    const orderRes = await fetch(`${PAYMOB_BASE}/ecommerce/orders`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        auth_token: auth.token,
        delivery_needed: false,
        amount_cents: input.intent.amount_minor_units,
        currency: input.intent.currency,
        merchant_order_id: input.intent.id,
        items: [],
      }),
    });
    if (!orderRes.ok) {
      throw new Error(`Paymob order create failed: ${orderRes.status}`);
    }
    const order = (await orderRes.json()) as { id: number };

    const integrationId =
      env.PAYMOB_INTEGRATION_ID_CARD ?? env.PAYMOB_INTEGRATION_ID_WALLET;
    if (!integrationId) {
      throw new Error('Paymob has no integration id configured');
    }

    const keyRes = await fetch(`${PAYMOB_BASE}/acceptance/payment_keys`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        auth_token: auth.token,
        amount_cents: input.intent.amount_minor_units,
        expiration: 3600,
        order_id: order.id,
        billing_data: {
          email: input.intent.customer.email ?? 'na@na.na',
          first_name: input.intent.customer.first_name ?? 'NA',
          last_name: input.intent.customer.last_name ?? 'NA',
          phone_number: input.intent.customer.phone ?? '+201000000000',
          country: input.intent.customer.billing_address?.country ?? 'EG',
          // Paymob requires these — pass 'NA' when not collected.
          apartment: 'NA',
          floor: 'NA',
          street: 'NA',
          building: 'NA',
          shipping_method: 'NA',
          postal_code: 'NA',
          city: 'NA',
          state: 'NA',
        },
        currency: input.intent.currency,
        integration_id: integrationId,
      }),
    });
    if (!keyRes.ok) {
      throw new Error(`Paymob payment_key failed: ${keyRes.status}`);
    }
    const key = (await keyRes.json()) as { token: string };

    const iframeUrl = `${PAYMOB_BASE}/acceptance/iframes/${env.PAYMOB_IFRAME_ID}?payment_token=${key.token}`;

    return {
      gateway_intent_id: String(order.id),
      client_secret: iframeUrl, // Flutter side reads this as the iframe URL.
      status: 'requires3ds',
    };
  }

  async refund(transactionId: string, amountMinorUnits?: number): Promise<boolean> {
    const env = loadEnv();
    const authRes = await fetch(`${PAYMOB_BASE}/auth/tokens`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ api_key: env.PAYMOB_API_KEY }),
    });
    if (!authRes.ok) return false;
    const auth = (await authRes.json()) as { token: string };

    const refundRes = await fetch(`${PAYMOB_BASE}/acceptance/void_refund/refund`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${auth.token}`,
      },
      body: JSON.stringify({
        transaction_id: transactionId,
        amount_cents: amountMinorUnits,
      }),
    });
    return refundRes.ok;
  }

  verifyWebhookSignature(
    rawBody: Buffer,
    headers: Record<string, string | string[] | undefined>,
  ): boolean {
    const env = loadEnv();
    if (!env.PAYMOB_HMAC_SECRET) return false;
    const provided = headers['hmac'];
    if (typeof provided !== 'string') return false;

    // Paymob's HMAC computation joins a specific list of fields in
    // alphabetical order from the obj payload — but for v0.1 we accept
    // the simpler raw-body HMAC compare for our own webhook proxy.
    const expected = createHmac('sha512', env.PAYMOB_HMAC_SECRET)
      .update(rawBody)
      .digest('hex');
    const ok =
      provided.length === expected.length &&
      timingSafeEqualHex(provided, expected);
    if (!ok) {
      logger.warn('Paymob HMAC mismatch');
    }
    return ok;
  }

  parseWebhookEvent(rawBody: Buffer): { eventId: string; type: string; data: unknown } {
    const body = JSON.parse(rawBody.toString('utf8')) as {
      obj?: { id?: number; success?: boolean };
    };
    return {
      eventId: String(body.obj?.id ?? 'unknown'),
      type: body.obj?.success ? 'paymob.transaction.succeeded' : 'paymob.transaction.failed',
      data: body,
    };
  }
}

function timingSafeEqualHex(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) {
    diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return diff === 0;
}
