import type { FastifyInstance } from 'fastify';
import { SaleHandler } from './sale.handler';

export function registerSaleRoutes(
  app: FastifyInstance,
  handler: SaleHandler,
): void {
  app.get(
    '/api/v1/sales',
    async (req, reply) => {
      const result = await handler.list(req);
      return reply.status(200).send(result);
    },
  );

  app.get(
    '/api/v1/sales/:id',
    async (req, reply) => {
      const result = await handler.get(req);
      return reply.status(200).send(result);
    },
  );

  app.post(
    '/api/v1/sales',
    async (req, reply) => {
      const result = await handler.create(req);
      return reply.status(201).send(result);
    },
  );
}
