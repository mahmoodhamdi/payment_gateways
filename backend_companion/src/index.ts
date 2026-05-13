import { loadEnv } from './config.js';
import { getAvailableGateways } from './gateways/registry.js';
import { logger } from './lib/logger.js';
import { buildServer } from './server.js';

const env = loadEnv();
const app = buildServer();

const configured = getAvailableGateways().map((g) => g.id);
logger.info(
  { gateways: configured, port: env.PORT, node_env: env.NODE_ENV },
  'starting payment_gateways backend',
);

if (configured.length === 0) {
  logger.warn(
    'No gateways are fully configured. Set the per-gateway env vars in .env (see .env.example).',
  );
}

app.listen(env.PORT, () => {
  logger.info(`payment_gateways backend listening on :${env.PORT}`);
});
