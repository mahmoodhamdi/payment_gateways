/**
 * Server-side gateway adapter contract. One implementation per supported
 * gateway. The HTTP routes in `src/routes/` dispatch to these.
 *
 * Note: secret keys live entirely server-side. Adapters read them from
 * the validated `Env` config, never accept them from request bodies.
 */

export interface CreateIntentInput {
  intent: {
    id: string;
    amount_minor_units: number;
    currency: string;
    customer: {
      id: string;
      email?: string;
      phone?: string;
      first_name?: string;
      last_name?: string;
      billing_address?: { country: string };
    };
    metadata?: Record<string, unknown>;
  };
}

export interface CreateIntentResult {
  /** Gateway-issued intent id (e.g. Stripe `pi_xxx`, Paymob order id). */
  gateway_intent_id: string;
  /** Opaque token / URL for the client. Format depends on the gateway. */
  client_secret?: string;
  /** Initial status (usually `pending` or `requires3ds`). */
  status:
    | 'pending'
    | 'processing'
    | 'requires3ds'
    | 'requiresExternalAction'
    | 'succeeded'
    | 'failed';
}

export interface ConfirmCardInput {
  gateway_intent_id: string;
  card: {
    number: string;
    exp_month: number;
    exp_year: number;
    cvv: string;
    cardholder_name?: string;
  };
  return_urls: { success: string; failure: string };
}

export interface ConfirmCardResult {
  status:
    | 'succeeded'
    | 'failed'
    | 'requires3ds';
  transaction_id?: string;
  action_url?: string;
  error_code?: string;
  error_reason?: string;
}

export interface GatewayAdapter {
  readonly id: string;
  /** Returns false when env doesn't carry the required secrets. */
  isAvailable(): boolean;
  createIntent(input: CreateIntentInput): Promise<CreateIntentResult>;
  confirmCard?(input: ConfirmCardInput): Promise<ConfirmCardResult>;
  refund(transactionId: string, amountMinorUnits?: number): Promise<boolean>;
  verifyWebhookSignature(rawBody: Buffer, headers: Record<string, string | string[] | undefined>): boolean;
  parseWebhookEvent(rawBody: Buffer): { eventId: string; type: string; data: unknown };
}
