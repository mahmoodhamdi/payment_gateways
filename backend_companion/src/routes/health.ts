import { Router } from 'express';

import { getAvailableGateways } from '../gateways/registry.js';

export function healthRouter(): Router {
  const router = Router();
  router.get('/health', (_req, res) => {
    const gateways = getAvailableGateways().map((g) => g.id).sort();
    res.json({
      status: 'ok',
      gateways_configured: gateways,
      version: '0.1.0',
      time: new Date().toISOString(),
    });
  });
  return router;
}
