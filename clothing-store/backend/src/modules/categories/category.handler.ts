import type { FastifyRequest } from 'fastify';
import { ok } from '../../shared/types';
import { CategoryService } from './category.service';
import { categoryIdParamSchema, createCategorySchema } from './category.schema';

export class CategoryHandler {
  constructor(private readonly service: CategoryService) {}

  async list(req: FastifyRequest) {
    const userId = (req.user as { id: number }).id;
    const result = await this.service.list(userId);
    return ok(result);
  }

  async create(req: FastifyRequest) {
    const userId = (req.user as { id: number }).id;
    const dto = createCategorySchema.parse(req.body);
    const result = await this.service.create(dto, userId);
    return ok(result);
  }

  async delete(req: FastifyRequest) {
    const userId = (req.user as { id: number }).id;
    const { id } = categoryIdParamSchema.parse(req.params);
    const result = await this.service.delete(id, userId);
    return ok(result);
  }
}
