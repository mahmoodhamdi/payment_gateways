import { createHmac } from 'node:crypto';

import { loadEnv } from '../config.js';
import type {
  CreateIntentInput,
  CreateIntentResult,
  GatewayAdapter,
} from './types.js';

const PAYTABS_REGION_HOSTS: Record<string, string> = {
  ARE: 'https://secure.paytabs.com',
  SAU: 'https://secure.paytabs.sa',
  KWT: 'https://secure-kw.paytabs.com',
  OMN: 'https://secure-oman.paytabs.com',
  JOR: 'https://secure-jordan.paytabs.com',
  EGY: 'https://secure-egypt.paytabs.com',
  GLOBAL: 'https://secure-global.paytabs.com',
};

export class PayTabsAdapter implements GatewayAdapter {
  readonly id = 'paytabs';

  isAvailable(): boolean {
    const env = loadEnv();
    return !!(env.PAYTABS_PROFILE_ID && env.PAYTABS_SERVER_KEY);
  }

  private get baseUrl(): string {
    const env = loadEnv();
    return PAYTABS_REGION_HOSTS[env.PAYTABS_REGION] ?? PAYTABS_REGION_HOSTS.GLOBAL;
  }

  async createIntent(input: CreateIntentInput): Promise<CreateIntentResult> {
    const env = loadEnv();
    if (!env.PAYTABS_PROFILE_ID || !env.PAYTABS_SERVER_KEY) {
      throw new Error('PayTabs not configured');
    }
    const response = await fetch(`${this.baseUrl}/payment/request`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: env.PAYTABS_SERVER_KEY,
      },
      body: JSON.stringify({
        profile_id: env.PAYTABS_PROFILE_ID,
        tran_type: 'sale',
        tran_class: 'ecom',
        cart_id: input.intent.id,
        cart_description: 'Order',
        cart_currency: input.intent.currency,
        cart_amount: (input.intent.amount_minor_units / 100).toFixed(2),
        customer_details: {
          name:
            `${input.intent.customer.first_name ?? ''} ${input.intent.customer.last_name ?? ''}`.trim() ||
            'Customer',
          email: input.intent.customer.email ?? 'na@na.na',
          phone: input.intent.customer.phone ?? '+966000000000',
          country: input.intent.customer.billing_address?.country ?? 'SA',
          street1: 'NA',
          city: 'NA',
          state: 'NA',
          zip: 'NA',
        },
        return: input.intent.id, // backend uses this to look up the order
      }),
    });
    if (!response.ok) {
      throw new Error(`PayTabs request failed: ${response.status}`);
    }
    const result = (await response.json()) as {
      tran_ref?: string;
      redirect_url?: string;
    };
    if (!result.tran_ref || !result.redirect_url) {
      throw new Error('PayTabs response missing tran_ref/redirect_url');
    }
    return {
      gateway_intent_id: result.tran_ref,
      client_secret: result.redirect_url,
      status: 'requires3ds',
    };
  }

  async refund(transactionId: string, amountMinorUnits?: number): Promise<boolean> {
    const env = loadEnv();
    if (!env.PAYTABS_PROFILE_ID || !env.PAYTABS_SERVER_KEY) return false;
    const response = await fetch(`${this.baseUrl}/payment/request`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: env.PAYTABS_SERVER_KEY,
      },
      body: JSON.stringify({
        profile_id: env.PAYTABS_PROFILE_ID,
        tran_type: 'refund',
        tran_class: 'ecom',
        cart_id: transactionId,
        cart_description: 'Refund',
        cart_currency: 'SAR',
        cart_amount: amountMinorUnits
          ? (amountMinorUnits / 100).toFixed(2)
          : undefined,
        tran_ref: transactionId,
      }),
    });
    return response.ok;
  }

  verifyWebhookSignature(
    rawBody: Buffer,
    headers: Record<string, string | string[] | undefined>,
  ): boolean {
    const env = loadEnv();
    if (!env.PAYTABS_SERVER_KEY) return false;
    const provided = headers['signature'];
    if (typeof provided !== 'string') return false;
    const expected = createHmac('sha256', env.PAYTABS_SERVER_KEY)
      .update(rawBody)
      .digest('hex');
    return provided === expected;
  }

  parseWebhookEvent(rawBody: Buffer): { eventId: string; type: string; data: unknown } {
    const body = JSON.parse(rawBody.toString('utf8')) as {
      tran_ref?: string;
      payment_result?: { response_status?: string };
    };
    return {
      eventId: body.tran_ref ?? 'unknown',
      type: `paytabs.${body.payment_result?.response_status ?? 'unknown'}`,
      data: body,
    };
  }
}
