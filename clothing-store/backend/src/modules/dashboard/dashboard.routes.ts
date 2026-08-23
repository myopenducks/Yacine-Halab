import type { FastifyInstance } from 'fastify';
import { DashboardHandler } from './dashboard.handler';

export function registerDashboardRoutes(
  app: FastifyInstance,
  handler: DashboardHandler,
): void {
  app.get(
    '/api/v1/dashboard/summary',
    async (req, reply) => {
      const result = await handler.summary(req);
      return reply.status(200).send(result);
    },
  );

  app.get(
    '/api/v1/dashboard/sales',
    async (req, reply) => {
      const result = await handler.sales(req);
      return reply.status(200).send(result);
    },
  );
}
