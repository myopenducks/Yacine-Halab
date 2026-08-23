import type { FastifyInstance } from 'fastify';
import { ProductHandler } from './product.handler';

export function registerProductRoutes(
  app: FastifyInstance,
  handler: ProductHandler,
): void {
  app.get(
    '/api/v1/products',
    async (req, reply) => {
      const result = await handler.list(req);
      return reply.status(200).send(result);
    },
  );

  app.get(
    '/api/v1/products/:id',
    async (req, reply) => {
      const result = await handler.get(req);
      return reply.status(200).send(result);
    },
  );

  app.post(
    '/api/v1/products',
    async (req, reply) => {
      const result = await handler.create(req);
      return reply.status(201).send(result);
    },
  );

  app.patch(
    '/api/v1/products/:id',
    async (req, reply) => {
      const result = await handler.update(req);
      return reply.status(200).send(result);
    },
  );

  app.delete(
    '/api/v1/products/:id',
    async (req, reply) => {
      const result = await handler.delete(req);
      return reply.status(204).send(result);
    },
  );
}
