import type { FastifyRequest } from 'fastify';
import { ok } from '../../shared/types';
import { ProductService } from './product.service';
import {
  createProductSchema,
  productIdParamSchema,
  productListQuerySchema,
  updateProductSchema,
} from './product.schema';

export class ProductHandler {
  constructor(private readonly service: ProductService) {}

  async list(req: FastifyRequest) {
    const query = productListQuerySchema.parse(req.query);
    const result = await this.service.list(query);
    return ok(result);
  }

  async get(req: FastifyRequest) {
    const { id } = productIdParamSchema.parse(req.params);
    const result = await this.service.getById(id);
    return ok(result);
  }

  async create(req: FastifyRequest) {
    const dto = createProductSchema.parse(req.body);
    const result = await this.service.create(dto);
    return ok(result);
  }

  async update(req: FastifyRequest) {
    const { id } = productIdParamSchema.parse(req.params);
    const dto = updateProductSchema.parse(req.body);
    const result = await this.service.update(id, dto);
    return ok(result);
  }

  async delete(req: FastifyRequest) {
    const { id } = productIdParamSchema.parse(req.params);
    await this.service.delete(id);
    return ok(null);
  }

  async bulkCategory(req: FastifyRequest) {
    const dto = (await import('./product.schema')).bulkCategorySchema.parse(req.body);
    const result = await this.service.bulkUpdateCategory(dto);
    return ok(result);
  }
}
