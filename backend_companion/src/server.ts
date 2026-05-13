import cors from 'cors';
import express from 'express';
import rateLimit from 'express-rate-limit';
import helmet from 'helmet';
import { pinoHttp } from 'pino-http';

import { loadEnv } from './config.js';
import { InMemoryTransactionStore } from './db/transactions.js';
import { InMemoryIdempotencyStore } from './lib/idempotency.js';
import { logger } from './lib/logger.js';
import { apiKeyAuth } from './middleware/auth.js';
import { errorHandler } from './middleware/error_handler.js';
import { checkoutRouter } from './routes/checkout.js';
import { dashboardRouter } from './routes/dashboard.js';
import { healthRouter } from './routes/health.js';
import { refundsRouter } from './routes/refunds.js';
import { transactionsRouter } from './routes/transactions.js';
import { webhooksRouter } from './routes/webhooks.js';

export function buildServer(): express.Express {
  const env = loadEnv();
  const app = express();
  const transactions = new InMemoryTransactionStore();
  const idempotency = new InMemoryIdempotencyStore();

  app.set('trust proxy', 1);

  app.use(
    helmet({
      crossOriginResourcePolicy: { policy: 'cross-origin' },
    }),
  );
  app.use(
    cors({
      origin: env.ALLOWED_ORIGINS
        ? env.ALLOWED_ORIGINS.split(',').map((s) => s.trim())
        : true,
      credentials: false,
    }),
  );
  app.use(pinoHttp({ logger }));

  // Webhooks must be mounted BEFORE the json body parser — they need
  // the raw body buffer for HMAC verification.
  app.use(webhooksRouter(transactions, idempotency));

  app.use(express.json({ limit: '256kb' }));
  app.use(
    rateLimit({
      windowMs: 60 * 1000,
      max: 120,
      standardHeaders: true,
      legacyHeaders: false,
    }),
  );

  // Public health.
  app.use(healthRouter());

  // Authenticated API.
  app.use('/api', apiKeyAuth);
  app.use('/api', checkoutRouter(transactions));
  app.use('/api', refundsRouter(transactions));
  app.use('/api', transactionsRouter(transactions));
  app.use('/api', dashboardRouter(transactions));

  app.use(errorHandler);

  return app;
}
