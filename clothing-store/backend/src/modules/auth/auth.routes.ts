import type { FastifyInstance } from 'fastify';
import { AuthHandler } from './auth.handler';

export function registerAuthRoutes(
  app: FastifyInstance,
  handler: AuthHandler,
): void {
  app.post(
    '/api/v1/auth/login',
    async (req, reply) => {
      const result = await handler.login(req);
      return reply.status(200).send(result);
    },
  );

  app.get(
    '/api/v1/auth/me',
    async (req, reply) => {
      const result = await handler.me(req);
      return reply.status(200).send(result);
    },
  );
}
