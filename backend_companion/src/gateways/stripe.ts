import Stripe from 'stripe';

import { loadEnv } from '../config.js';
import { logger } from '../lib/logger.js';
import type {
  ConfirmCardInput,
  ConfirmCardResult,
  CreateIntentInput,
  CreateIntentResult,
  GatewayAdapter,
} from './types.js';

export class StripeAdapter implements GatewayAdapter {
  readonly id = 'stripe';

  private get client(): Stripe {
    const env = loadEnv();
    if (!env.STRIPE_SECRET_KEY) {
      throw new Error('Stripe secret key is not configured.');
    }
    return new Stripe(env.STRIPE_SECRET_KEY);
  }

  isAvailable(): boolean {
    const env = loadEnv();
    return !!(env.STRIPE_SECRET_KEY && env.STRIPE_WEBHOOK_SECRET);
  }

  async createIntent(input: CreateIntentInput): Promise<CreateIntentResult> {
    const stripe = this.client;
    const intent = await stripe.paymentIntents.create({
      amount: input.intent.amount_minor_units,
      currency: input.intent.currency.toLowerCase(),
      automatic_payment_methods: { enabled: true },
      metadata: {
        app_intent_id: input.intent.id,
        app_customer_id: input.intent.customer.id,
      },
      receipt_email: input.intent.customer.email,
    });
    return {
      gateway_intent_id: intent.id,
      client_secret: intent.client_secret ?? undefined,
      status: 'pending',
    };
  }

  async confirmCard(input: ConfirmCardInput): Promise<ConfirmCardResult> {
    const stripe = this.client;
    try {
      const paymentMethod = await stripe.paymentMethods.create({
        type: 'card',
        card: {
          number: input.card.number,
          exp_month: input.card.exp_month,
          exp_year: input.card.exp_year,
          cvc: input.card.cvv,
        },
        billing_details: input.card.cardholder_name
          ? { name: input.card.cardholder_name }
          : undefined,
      });
      const confirmed = await stripe.paymentIntents.confirm(
        input.gateway_intent_id,
        {
          payment_method: paymentMethod.id,
          return_url: input.return_urls.success,
        },
      );
      switch (confirmed.status) {
        case 'succeeded':
          return { status: 'succeeded', transaction_id: confirmed.id };
        case 'requires_action':
        case 'requires_confirmation':
          return {
            status: 'requires3ds',
            transaction_id: confirmed.id,
            action_url:
              confirmed.next_action?.redirect_to_url?.url ?? undefined,
          };
        default:
          return {
            status: 'failed',
            transaction_id: confirmed.id,
            error_code: 'card_declined',
          };
      }
    } catch (e) {
      if (e instanceof Stripe.errors.StripeCardError) {
        return {
          status: 'failed',
          error_code: this.mapStripeErrorCode(e.code ?? ''),
          error_reason: e.message,
        };
      }
      logger.error({ err: e }, 'Stripe confirmCard failed');
      return { status: 'failed', error_code: 'card_declined' };
    }
  }

  async refund(transactionId: string, amountMinorUnits?: number): Promise<boolean> {
    try {
      await this.client.refunds.create({
        payment_intent: transactionId,
        amount: amountMinorUnits,
      });
      return true;
    } catch (e) {
      logger.error({ err: e, transactionId }, 'Stripe refund failed');
      return false;
    }
  }

  verifyWebhookSignature(
    rawBody: Buffer,
    headers: Record<string, string | string[] | undefined>,
  ): boolean {
    const env = loadEnv();
    if (!env.STRIPE_WEBHOOK_SECRET) return false;
    const sig = headers['stripe-signature'];
    if (!sig || Array.isArray(sig)) return false;
    try {
      this.client.webhooks.constructEvent(
        rawBody,
        sig,
        env.STRIPE_WEBHOOK_SECRET,
      );
      return true;
    } catch (e) {
      logger.warn({ err: e }, 'Stripe webhook signature verification failed');
      return false;
    }
  }

  parseWebhookEvent(rawBody: Buffer): {
    eventId: string;
    type: string;
    data: unknown;
  } {
    const event = JSON.parse(rawBody.toString('utf8')) as {
      id: string;
      type: string;
      data: unknown;
    };
    return { eventId: event.id, type: event.type, data: event.data };
  }

  private mapStripeErrorCode(stripeCode: string): string {
    switch (stripeCode) {
      case 'card_declined':
        return 'card_declined';
      case 'expired_card':
        return 'expired_card';
      case 'incorrect_cvc':
      case 'invalid_cvc':
        return 'invalid_cvv';
      case 'insufficient_funds':
        return 'insufficient_funds';
      case 'authentication_required':
        return '3ds_failed';
      default:
        return 'card_declined';
    }
  }
}
