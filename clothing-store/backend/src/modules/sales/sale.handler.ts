import type { FastifyRequest } from 'fastify';
import { ok } from '../../shared/types';
import { SaleService } from './sale.service';
import {
  createSaleSchema,
  saleIdParamSchema,
  saleListQuerySchema,
} from './sale.schema';

export class SaleHandler {
  constructor(private readonly service: SaleService) {}

  async list(req: FastifyRequest) {
    const userId = (req.user as { id: number }).id;
    const query = saleListQuerySchema.parse(req.query);
    const result = await this.service.list(query, userId);
    return ok(result);
  }

  async get(req: FastifyRequest) {
    const userId = (req.user as { id: number }).id;
    const { id } = saleIdParamSchema.parse(req.params);
    const result = await this.service.getById(id, userId);
    return ok(result);
  }

  async create(req: FastifyRequest) {
    const userId = (req.user as { id: number }).id;
    const dto = createSaleSchema.parse(req.body);
    const result = await this.service.create(dto, userId);
    return ok(result);
  }

  async recordPayment(req: FastifyRequest) {
    const userId = (req.user as { id: number }).id;
    const { id } = saleIdParamSchema.parse(req.params);
    const dto = (await import('./sale.schema')).recordPaymentSchema.parse(req.body);
    const result = await this.service.recordPayment(id, dto, userId);
    return ok(result);
  }

  async update(req: FastifyRequest) {
    const userId = (req.user as { id: number }).id;
    const { id } = saleIdParamSchema.parse(req.params);
    const dto = (await import('./sale.schema')).updateSaleSchema.parse(req.body);
    const result = await this.service.update(id, dto, userId);
    return ok(result);
  }

  async delete(req: FastifyRequest) {
    const userId = (req.user as { id: number }).id;
    const { id } = saleIdParamSchema.parse(req.params);
    const result = await this.service.delete(id, userId);
    return ok(result);
  }

  async clearHistory(req: FastifyRequest) {
    const userId = (req.user as { id: number }).id;
    const restock = (req.query as { restock?: string })?.restock !== 'false';
    const result = await this.service.clearHistory(userId, restock);
    return ok(result);
  }
}
