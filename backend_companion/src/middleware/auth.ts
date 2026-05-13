import type { NextFunction, Request, Response } from 'express';

import { loadEnv } from '../config.js';

/**
 * Lightweight API key check. Clients send `Authorization: Bearer <API_KEY>`.
 *
 * For multi-tenant deployments, replace with per-tenant key lookups against
 * your DB and attach `req.tenant = ...`.
 */
export function apiKeyAuth(req: Request, res: Response, next: NextFunction): void {
  const env = loadEnv();
  const header = req.header('authorization') ?? '';
  const expected = `Bearer ${env.API_KEY}`;
  if (header !== expected) {
    res.status(401).json({ error: 'unauthorized' });
    return;
  }
  next();
}
