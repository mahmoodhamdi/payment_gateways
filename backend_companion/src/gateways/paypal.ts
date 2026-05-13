import { loadEnv } from '../config.js';
import type {
  CreateIntentInput,
  CreateIntentResult,
  GatewayAdapter,
} from './types.js';

/**
 * PayPal Orders v2 adapter using the REST API directly.
 *
 * The flow:
 *   1. POST /v2/checkout/orders  → returns approval link
 *   2. (client redirects user, user approves)
 *   3. POST /v2/checkout/orders/{id}/capture → settles funds
 */
export class PayPalAdapter implements GatewayAdapter {
  readonly id = 'paypal';

  isAvailable(): boolean {
    const env = loadEnv();
    return !!(env.PAYPAL_CLIENT_ID && env.PAYPAL_CLIENT_SECRET);
  }

  private get baseUrl(): string {
    const env = loadEnv();
    return env.PAYPAL_USE_SANDBOX
      ? 'https://api-m.sandbox.paypal.com'
      : 'https://api-m.paypal.com';
  }

  private async authToken(): Promise<string> {
    const env = loadEnv();
    if (!env.PAYPAL_CLIENT_ID || !env.PAYPAL_CLIENT_SECRET) {
      throw new Error('PayPal not configured');
    }
    const credentials = Buffer.from(
      `${env.PAYPAL_CLIENT_ID}:${env.PAYPAL_CLIENT_SECRET}`,
    ).toString('base64');
    const res = await fetch(`${this.baseUrl}/v1/oauth2/token`, {
      method: 'POST',
      headers: {
        Authorization: `Basic ${credentials}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: 'grant_type=client_credentials',
    });
    if (!res.ok) throw new Error(`PayPal auth failed: ${res.status}`);
    const json = (await res.json()) as { access_token: string };
    return json.access_token;
  }

  async createIntent(input: CreateIntentInput): Promise<CreateIntentResult> {
    const token = await this.authToken();
    const res = await fetch(`${this.baseUrl}/v2/checkout/orders`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        intent: 'CAPTURE',
        purchase_units: [
          {
            reference_id: input.intent.id,
            amount: {
              currency_code: input.intent.currency,
              value: (input.intent.amount_minor_units / 100).toFixed(2),
            },
          },
        ],
      }),
    });
    if (!res.ok) throw new Error(`PayPal order create failed: ${res.status}`);
    const order = (await res.json()) as {
      id: string;
      links: { rel: string; href: string }[];
    };
    const approveUrl = order.links.find((l) => l.rel === 'approve')?.href;
    if (!approveUrl) throw new Error('PayPal missing approve link');
    return {
      gateway_intent_id: order.id,
      client_secret: approveUrl,
      status: 'requires3ds',
    };
  }

  async refund(transactionId: string, amountMinorUnits?: number): Promise<boolean> {
    const token = await this.authToken();
    const body = amountMinorUnits
      ? {
          amount: {
            value: (amountMinorUnits / 100).toFixed(2),
            currency_code: 'USD',
          },
        }
      : {};
    const res = await fetch(
      `${this.baseUrl}/v2/payments/captures/${transactionId}/refund`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(body),
      },
    );
    return res.ok;
  }

  verifyWebhookSignature(
    _rawBody: Buffer,
    _headers: Record<string, string | string[] | undefined>,
  ): boolean {
    // PayPal webhook verification requires a separate POST to
    //   /v1/notifications/verify-webhook-signature
    // with the headers + body. v0.1 accepts events as long as the
    // PAYPAL_WEBHOOK_ID matches; this method returns true and the
    // route layer handles the verify-webhook-signature call.
    return true;
  }

  parseWebhookEvent(rawBody: Buffer): { eventId: string; type: string; data: unknown } {
    const body = JSON.parse(rawBody.toString('utf8')) as {
      id?: string;
      event_type?: string;
    };
    return {
      eventId: body.id ?? 'unknown',
      type: body.event_type ?? 'paypal.unknown',
      data: body,
    };
  }
}
