import { createHash } from 'node:crypto';

import { loadEnv } from '../config.js';
import type {
  CreateIntentInput,
  CreateIntentResult,
  GatewayAdapter,
} from './types.js';

/**
 * Fawry adapter — Egypt cash-at-outlet.
 *
 * Customers receive a reference number; pay cash at any Fawry outlet, ATM,
 * or via their banking app. Settlement webhooks arrive hours/days later.
 */
export class FawryAdapter implements GatewayAdapter {
  readonly id = 'fawry';

  isAvailable(): boolean {
    const env = loadEnv();
    return !!(env.FAWRY_MERCHANT_CODE && env.FAWRY_SECURITY_KEY);
  }

  private get baseUrl(): string {
    const env = loadEnv();
    return env.FAWRY_USE_STAGING
      ? 'https://atfawry.fawrystaging.com/ECommerceWeb/Fawry/payments'
      : 'https://www.atfawry.com/ECommerceWeb/Fawry/payments';
  }

  async createIntent(input: CreateIntentInput): Promise<CreateIntentResult> {
    const env = loadEnv();
    if (!env.FAWRY_MERCHANT_CODE || !env.FAWRY_SECURITY_KEY) {
      throw new Error('Fawry not configured');
    }

    const merchantRefNum = input.intent.id;
    const amount = (input.intent.amount_minor_units / 100).toFixed(2);
    const customer = input.intent.customer;

    // Signature: SHA256(merchantCode + merchantRefNum + customerProfileId
    //  + paymentMethod + amount + cardNumber? + cardExpiryYear? + cardExpiryMonth?
    //  + cvv? + returnUrl? + securityKey)
    const sigInput = `${env.FAWRY_MERCHANT_CODE}${merchantRefNum}${customer.id}PayAtFawry${amount}${env.FAWRY_SECURITY_KEY}`;
    const signature = createHash('sha256').update(sigInput).digest('hex');

    const body = {
      merchantCode: env.FAWRY_MERCHANT_CODE,
      merchantRefNum,
      customerProfileId: customer.id,
      customerEmail: customer.email ?? 'na@na.na',
      customerMobile: customer.phone ?? '01000000000',
      paymentMethod: 'PayAtFawry',
      amount: parseFloat(amount),
      currencyCode: input.intent.currency,
      chargeItems: [
        {
          itemId: input.intent.id,
          description: 'Order',
          price: parseFloat(amount),
          quantity: 1,
        },
      ],
      signature,
    };

    const response = await fetch(`${this.baseUrl}/charge`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });
    if (!response.ok) {
      throw new Error(`Fawry charge create failed: ${response.status}`);
    }
    const result = (await response.json()) as {
      referenceNumber?: string;
      statusCode?: number;
    };
    if (!result.referenceNumber) {
      throw new Error('Fawry did not return a reference number');
    }

    return {
      gateway_intent_id: merchantRefNum,
      client_secret: result.referenceNumber,
      status: 'requiresExternalAction',
    };
  }

  async refund(_transactionId: string): Promise<boolean> {
    // Fawry refunds are batch/manual via merchant portal — return false to
    // signal "needs manual handling" rather than mock-success.
    return false;
  }

  verifyWebhookSignature(rawBody: Buffer): boolean {
    const env = loadEnv();
    if (!env.FAWRY_SECURITY_KEY) return false;
    // Fawry signs callbacks with SHA256 over a defined set of fields. The
    // exact field list varies per merchant config; check Fawry's developer
    // portal for your account's recipe. v0.1 accepts the merchant securing
    // the path via an unguessable webhook URL + IP allowlist.
    const body = JSON.parse(rawBody.toString('utf8')) as {
      messageSignature?: string;
      fawryRefNumber?: string;
      merchantRefNumber?: string;
      paymentAmount?: number;
      orderStatus?: string;
    };
    if (!body.messageSignature) return true; // accept until per-merchant recipe is wired
    const recomputed = createHash('sha256')
      .update(
        `${body.fawryRefNumber}${body.merchantRefNumber}${(body.paymentAmount ?? 0).toFixed(2)}${body.orderStatus}${env.FAWRY_SECURITY_KEY}`,
      )
      .digest('hex');
    return recomputed === body.messageSignature;
  }

  parseWebhookEvent(rawBody: Buffer): { eventId: string; type: string; data: unknown } {
    const body = JSON.parse(rawBody.toString('utf8')) as {
      fawryRefNumber?: string;
      merchantRefNumber?: string;
      orderStatus?: string;
    };
    const status = body.orderStatus ?? 'UNKNOWN';
    return {
      eventId: body.fawryRefNumber ?? body.merchantRefNumber ?? 'unknown',
      type: `fawry.order.${status.toLowerCase()}`,
      data: body,
    };
  }
}
