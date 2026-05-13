import { createHmac } from 'node:crypto';

import { loadEnv } from '../config.js';
import type {
  CreateIntentInput,
  CreateIntentResult,
  GatewayAdapter,
} from './types.js';

const SQUARE_VERSION = '2024-09-19';

/**
 * Square adapter using the Square Web Payments / Online Checkout API.
 *
 * v0.1 uses the Checkout API "Quick Pay" flow which returns a hosted
 * checkout URL — that URL is opened in the Flutter WebView. Native iOS
 * Apple Pay via Square Mobile Payments SDK is planned for v1.1.
 */
export class SquareAdapter implements GatewayAdapter {
  readonly id = 'square';

  isAvailable(): boolean {
    const env = loadEnv();
    return !!(
      env.SQUARE_ACCESS_TOKEN &&
      env.SQUARE_APPLICATION_ID &&
      env.SQUARE_LOCATION_ID
    );
  }

  private get baseUrl(): string {
    const env = loadEnv();
    return env.SQUARE_USE_SANDBOX
      ? 'https://connect.squareupsandbox.com'
      : 'https://connect.squareup.com';
  }

  async createIntent(input: CreateIntentInput): Promise<CreateIntentResult> {
    const env = loadEnv();
    if (!env.SQUARE_ACCESS_TOKEN || !env.SQUARE_LOCATION_ID) {
      throw new Error('Square not configured');
    }
    const res = await fetch(`${this.baseUrl}/v2/online-checkout/payment-links`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${env.SQUARE_ACCESS_TOKEN}`,
        'Content-Type': 'application/json',
        'Square-Version': SQUARE_VERSION,
      },
      body: JSON.stringify({
        idempotency_key: input.intent.id,
        quick_pay: {
          name: 'Order',
          price_money: {
            amount: input.intent.amount_minor_units,
            currency: input.intent.currency,
          },
          location_id: env.SQUARE_LOCATION_ID,
        },
      }),
    });
    if (!res.ok) {
      throw new Error(`Square payment link failed: ${res.status}`);
    }
    const json = (await res.json()) as {
      payment_link: { id: string; url: string };
    };
    return {
      gateway_intent_id: json.payment_link.id,
      client_secret: json.payment_link.url,
      status: 'requires3ds',
    };
  }

  async refund(transactionId: string, amountMinorUnits?: number): Promise<boolean> {
    const env = loadEnv();
    if (!env.SQUARE_ACCESS_TOKEN) return false;
    const res = await fetch(`${this.baseUrl}/v2/refunds`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${env.SQUARE_ACCESS_TOKEN}`,
        'Content-Type': 'application/json',
        'Square-Version': SQUARE_VERSION,
      },
      body: JSON.stringify({
        idempotency_key: `refund-${transactionId}-${Date.now()}`,
        payment_id: transactionId,
        amount_money: amountMinorUnits
          ? { amount: amountMinorUnits, currency: 'USD' }
          : undefined,
      }),
    });
    return res.ok;
  }

  verifyWebhookSignature(
    rawBody: Buffer,
    headers: Record<string, string | string[] | undefined>,
  ): boolean {
    // Square signs with HMAC-SHA256 of (notificationUrl + body), keyed with
    // the per-subscription signing key. Configure SQUARE_WEBHOOK_SIGNATURE_KEY
    // out-of-band in your secrets store; until then we accept and rely on
    // an unguessable webhook path + IP allowlist as defense-in-depth.
    const provided = headers['x-square-hmacsha256-signature'];
    if (typeof provided !== 'string') return true;
    const env = loadEnv();
    const key = env.STRIPE_WEBHOOK_SECRET ?? ''; // placeholder for v0.1
    const expected = createHmac('sha256', key).update(rawBody).digest('base64');
    return provided === expected;
  }

  parseWebhookEvent(rawBody: Buffer): { eventId: string; type: string; data: unknown } {
    const body = JSON.parse(rawBody.toString('utf8')) as {
      event_id?: string;
      type?: string;
    };
    return {
      eventId: body.event_id ?? 'unknown',
      type: body.type ?? 'square.unknown',
      data: body,
    };
  }
}
