import type { FastifyRequest } from 'fastify';
import { getJwtPayload } from '../../plugins/auth';
import { ExpenseService } from './expense.service';
import { ok } from '../../shared/types';
import {
  CreateExpenseSchema,
  ExpenseQuerySchema,
  UpdateExpenseSchema,
} from './expense.schema';

export class ExpenseHandler {
  constructor(private readonly service: ExpenseService) {}

  async create(req: FastifyRequest) {
    const { sub: userId } = getJwtPayload(req);
    const dto = CreateExpenseSchema.parse(req.body);
    const result = await this.service.create(dto, userId);
    return ok(result);
  }

  async get(req: FastifyRequest<{ Params: { id: string } }>) {
    const { sub: userId } = getJwtPayload(req);
    const id = Number(req.params.id);
    const result = await this.service.getById(id, userId);
    return ok(result);
  }

  async update(req: FastifyRequest<{ Params: { id: string } }>) {
    const { sub: userId } = getJwtPayload(req);
    const id = Number(req.params.id);
    const dto = UpdateExpenseSchema.parse(req.body);
    const result = await this.service.update(id, dto, userId);
    return ok(result);
  }

  async delete(req: FastifyRequest<{ Params: { id: string } }>) {
    const { sub: userId } = getJwtPayload(req);
    const id = Number(req.params.id);
    await this.service.delete(id, userId);
    return ok({ success: true });
  }

  async list(req: FastifyRequest) {
    const { sub: userId } = getJwtPayload(req);
    const query = ExpenseQuerySchema.parse(req.query);
    const result = await this.service.list(query, userId);
    return ok(result);
  }

  async summary(req: FastifyRequest) {
    const { sub: userId } = getJwtPayload(req);
    const { from, to } = req.query as { from?: string; to?: string };
    const result = await this.service.summary({ from, to }, userId);
    return ok(result);
  }
}
