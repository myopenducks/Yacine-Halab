import type { FastifyInstance, FastifyRequest } from 'fastify';
import { AppError } from '../shared/errors';

export interface JwtPayload {
  sub: number;
  username: string;
}

export function isJwtPayload(v: unknown): v is JwtPayload {
  if (typeof v !== 'object' || v === null) return false;
  const rawSub = (v as { sub?: unknown }).sub;
  const subNum = typeof rawSub === 'string' ? Number(rawSub) : rawSub;
  return (
    typeof subNum === 'number' &&
    Number.isFinite(subNum) &&
    typeof (v as { username?: unknown }).username === 'string'
  );
}

export function getJwtPayload(req: FastifyRequest): JwtPayload {
  const stored = (req as unknown as { __jwt?: JwtPayload }).__jwt;
  if (stored) return stored;
  if (isJwtPayload(req.user)) {
    const rawSub = (req.user as { sub: string | number }).sub;
    const sub = typeof rawSub === 'string' ? Number(rawSub) : rawSub;
    return { sub, username: (req.user as { username: string }).username };
  }
  throw new AppError({
    code: 'UNAUTHORIZED',
    statusCode: 401,
    message: 'Invalid token payload',
  });
}

const PUBLIC_ROUTES: Array<{ method: string; url: string }> = [
  { method: 'GET', url: '/health' },
  { method: 'POST', url: '/api/v1/auth/login' },
  { method: 'POST', url: '/api/v1/auth/guest' },
  { method: 'POST', url: '/api/v1/auth/register' },
];

function stripQuery(url: string | undefined): string {
  if (!url) return '';
  const idx = url.indexOf('?');
  return idx >= 0 ? url.slice(0, idx) : url;
}

function isPublic(req: FastifyRequest): boolean {
  const method = (req.method ?? req.raw.method ?? '').toUpperCase();
  const rawUrl = stripQuery(req.url ?? req.raw.url ?? '').toLowerCase().replace(/\/+$/, '');
  const routerPath = (req.routerPath ?? '').toLowerCase().replace(/\/+$/, '');

  return PUBLIC_ROUTES.some((r) => {
    const targetUrl = r.url.toLowerCase().replace(/\/+$/, '');
    const methodMatches = r.method.toUpperCase() === method;
    return (
      methodMatches &&
      (rawUrl === targetUrl ||
        routerPath === targetUrl ||
        rawUrl.endsWith(targetUrl))
    );
  });
}

export async function registerAuth(app: FastifyInstance): Promise<void> {
  app.addHook('onRequest', async (req) => {
    if (isPublic(req)) return;

    try {
      const decoded = await req.jwtVerify();
      if (!isJwtPayload(decoded)) {
        throw new AppError({
          code: 'UNAUTHORIZED',
          statusCode: 401,
          message: 'Invalid token payload',
        });
      }
      const rawSub = (decoded as { sub: string | number }).sub;
      const sub = typeof rawSub === 'string' ? Number(rawSub) : rawSub;
      const normalized: JwtPayload = {
        sub,
        username: (decoded as { username: string }).username,
      };
      (req as unknown as { __jwt: JwtPayload }).__jwt = normalized;
    } catch (err) {
      if (err instanceof AppError) throw err;
      const msg =
        typeof (err as { message?: string }).message === 'string'
          ? ((err as { message: string }).message as string)
          : 'Authentication required';
      throw new AppError({
        code: 'UNAUTHORIZED',
        statusCode: 401,
        message: msg,
      });
    }
  });
}
