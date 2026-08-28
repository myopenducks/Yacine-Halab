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

  app.post(
    '/api/v1/auth/register',
    async (req, reply) => {
      const result = await handler.register(req);
      return reply.status(201).send(result);
    },
  );

  app.post(
    '/api/v1/auth/guest',
    async (req, reply) => {
      const result = await handler.guest(req);
      return reply.status(201).send(result);
    },
  );

  app.post(
    '/api/v1/auth/change-password',
    async (req, reply) => {
      const result = await handler.changePassword(req);
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
