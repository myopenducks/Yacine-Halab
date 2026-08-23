import type { FastifyInstance } from 'fastify';
import { CategoryHandler } from './category.handler';

export function registerCategoryRoutes(
  app: FastifyInstance,
  handler: CategoryHandler,
): void {
  app.get(
    '/api/v1/categories',
    async (req, reply) => {
      const result = await handler.list();
      return reply.status(200).send(result);
    },
  );
}
