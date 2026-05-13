import pino from 'pino';

import { loadEnv } from '../config.js';
import { redact } from './redact.js';

const env = loadEnv();

export const logger = pino({
  level: env.LOG_LEVEL,
  formatters: {
    log(object) {
      return redact(object) as Record<string, unknown>;
    },
  },
  redact: {
    paths: [
      'card.number',
      'card.cvv',
      'card.exp_month',
      'card.exp_year',
      'card_number',
      'cvv',
      'cvc',
      'authorization',
      'secret',
      'api_key',
      'access_token',
      'client_secret',
      'webhook_secret',
    ],
    censor: '***',
  },
  transport:
    env.NODE_ENV === 'development'
      ? {
          target: 'pino-pretty',
          options: { colorize: true, translateTime: 'HH:MM:ss.l' },
        }
      : undefined,
});
