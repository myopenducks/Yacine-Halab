import type { FastifyRequest } from 'fastify';
import { ok } from '../../shared/types';
import { CategoryService } from './category.service';
import { categoryIdParamSchema, createCategorySchema } from './category.schema';

export class CategoryHandler {
  constructor(private readonly service: CategoryService) {}

  async list() {
    const result = await this.service.list();
    return ok(result);
  }

  async create(req: FastifyRequest) {
    const dto = createCategorySchema.parse(req.body);
    const result = await this.service.create(dto);
    return ok(result);
  }

  async delete(req: FastifyRequest) {
    const { id } = categoryIdParamSchema.parse(req.params);
    const result = await this.service.delete(id);
    return ok(result);
  }
}
