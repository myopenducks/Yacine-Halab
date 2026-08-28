import type { FastifyRequest } from 'fastify';
import { getJwtPayload } from '../../plugins/auth';
import { ExpenseService } from './expense.service';
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
    return this.service.create(dto, userId);
  }

  async get(req: FastifyRequest<{ Params: { id: string } }>) {
    const { sub: userId } = getJwtPayload(req);
    const id = Number(req.params.id);
    return this.service.getById(id, userId);
  }

  async update(req: FastifyRequest<{ Params: { id: string } }>) {
    const { sub: userId } = getJwtPayload(req);
    const id = Number(req.params.id);
    const dto = UpdateExpenseSchema.parse(req.body);
    return this.service.update(id, dto, userId);
  }

  async delete(req: FastifyRequest<{ Params: { id: string } }>) {
    const { sub: userId } = getJwtPayload(req);
    const id = Number(req.params.id);
    await this.service.delete(id, userId);
    return { success: true };
  }

  async list(req: FastifyRequest) {
    const { sub: userId } = getJwtPayload(req);
    const query = ExpenseQuerySchema.parse(req.query);
    return this.service.list(query, userId);
  }

  async summary(req: FastifyRequest) {
    const { sub: userId } = getJwtPayload(req);
    const { from, to } = req.query as { from?: string; to?: string };
    return this.service.summary({ from, to }, userId);
  }
}
