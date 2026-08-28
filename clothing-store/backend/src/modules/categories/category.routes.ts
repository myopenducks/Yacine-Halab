import type { FastifyInstance } from 'fastify';
import { CategoryHandler } from './category.handler';

export function registerCategoryRoutes(
  app: FastifyInstance,
  handler: CategoryHandler,
): void {
  app.get(
    '/api/v1/categories',
    async (_req, reply) => {
      const result = await handler.list();
      return reply.status(200).send(result);
    },
  );

  app.post(
    '/api/v1/categories',
    async (req, reply) => {
      const result = await handler.create(req);
      return reply.status(201).send(result);
    },
  );

  app.delete(
    '/api/v1/categories/:id',
    async (req, reply) => {
      const result = await handler.delete(req);
      return reply.status(200).send(result);
    },
  );
}
