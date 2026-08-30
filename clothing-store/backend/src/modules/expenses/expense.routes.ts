import type { FastifyInstance } from 'fastify';
import { ExpenseHandler } from './expense.handler';
import { ok } from '../../shared/types';

export function registerExpenseRoutes(
  app: FastifyInstance,
  handler: ExpenseHandler,
): void {
  app.get('/api/v1/expenses', async (req, reply) => {
    const result = await handler.list(req);
    return reply.status(200).send(ok(result));
  });

  app.get('/api/v1/expenses/summary', async (req, reply) => {
    const result = await handler.summary(req);
    return reply.status(200).send(ok(result));
  });

  app.get('/api/v1/expenses/:id', async (req, reply) => {
    const result = await handler.get(req as any);
    return reply.status(200).send(result);
  });

  app.post('/api/v1/expenses', async (req, reply) => {
    const result = await handler.create(req);
    return reply.status(201).send(result);
  });

  app.patch('/api/v1/expenses/:id', async (req, reply) => {
    const result = await handler.update(req as any);
    return reply.status(200).send(result);
  });

  app.delete('/api/v1/expenses/:id', async (req, reply) => {
    const result = await handler.delete(req as any);
    return reply.status(200).send(result);
  });
}
