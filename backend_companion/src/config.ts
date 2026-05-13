import 'dotenv/config';
import { z } from 'zod';

const envSchema = z.object({
  PORT: z.coerce.number().int().positive().default(4000),
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  LOG_LEVEL: z
    .enum(['fatal', 'error', 'warn', 'info', 'debug', 'trace'])
    .default('info'),
  API_KEY: z.string().min(16, 'API_KEY must be at least 16 chars'),
  ALLOWED_ORIGINS: z.string().default(''),

  // Stripe
  STRIPE_SECRET_KEY: z.string().startsWith('sk_').optional(),
  STRIPE_WEBHOOK_SECRET: z.string().startsWith('whsec_').optional(),

  // Paymob
  PAYMOB_API_KEY: z.string().optional(),
  PAYMOB_HMAC_SECRET: z.string().optional(),
  PAYMOB_IFRAME_ID: z.coerce.number().int().optional(),
  PAYMOB_INTEGRATION_ID_CARD: z.coerce.number().int().optional(),
  PAYMOB_INTEGRATION_ID_WALLET: z.coerce.number().int().optional(),

  // PayTabs
  PAYTABS_PROFILE_ID: z.string().optional(),
  PAYTABS_SERVER_KEY: z.string().optional(),
  PAYTABS_REGION: z
    .enum(['ARE', 'SAU', 'KWT', 'OMN', 'JOR', 'EGY', 'GLOBAL'])
    .default('GLOBAL'),

  // Fawry
  FAWRY_MERCHANT_CODE: z.string().optional(),
  FAWRY_SECURITY_KEY: z.string().optional(),
  FAWRY_USE_STAGING: z.coerce.boolean().default(true),

  // PayPal
  PAYPAL_CLIENT_ID: z.string().optional(),
  PAYPAL_CLIENT_SECRET: z.string().optional(),
  PAYPAL_USE_SANDBOX: z.coerce.boolean().default(true),

  // Square
  SQUARE_ACCESS_TOKEN: z.string().optional(),
  SQUARE_APPLICATION_ID: z.string().optional(),
  SQUARE_LOCATION_ID: z.string().optional(),
  SQUARE_USE_SANDBOX: z.coerce.boolean().default(true),

  // Storage (optional in v0.1; in-memory if absent)
  MONGO_URI: z.string().optional(),
});

export type Env = z.infer<typeof envSchema>;

let cached: Env | undefined;

export function loadEnv(): Env {
  if (cached) return cached;
  const parsed = envSchema.safeParse(process.env);
  if (!parsed.success) {
    const issues = parsed.error.issues
      .map((i) => `  ${i.path.join('.')}: ${i.message}`)
      .join('\n');
    throw new Error(
      `Invalid environment configuration:\n${issues}\n\n` +
        'Copy .env.example to .env.local and fill in the required values.',
    );
  }
  cached = parsed.data;
  return cached;
}

export function gatewayConfigured(
  env: Env,
  gateway: 'stripe' | 'paymob' | 'paytabs' | 'fawry' | 'paypal' | 'square',
): boolean {
  switch (gateway) {
    case 'stripe':
      return !!(env.STRIPE_SECRET_KEY && env.STRIPE_WEBHOOK_SECRET);
    case 'paymob':
      return !!(
        env.PAYMOB_API_KEY &&
        env.PAYMOB_HMAC_SECRET &&
        env.PAYMOB_IFRAME_ID
      );
    case 'paytabs':
      return !!(env.PAYTABS_PROFILE_ID && env.PAYTABS_SERVER_KEY);
    case 'fawry':
      return !!(env.FAWRY_MERCHANT_CODE && env.FAWRY_SECURITY_KEY);
    case 'paypal':
      return !!(env.PAYPAL_CLIENT_ID && env.PAYPAL_CLIENT_SECRET);
    case 'square':
      return !!(
        env.SQUARE_ACCESS_TOKEN &&
        env.SQUARE_APPLICATION_ID &&
        env.SQUARE_LOCATION_ID
      );
  }
}
