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
    const query = saleListQuerySchema.parse(req.query);
    const result = await this.service.list(query);
    return ok(result);
  }

  async get(req: FastifyRequest) {
    const { id } = saleIdParamSchema.parse(req.params);
    const result = await this.service.getById(id);
    return ok(result);
  }

  async create(req: FastifyRequest) {
    const dto = createSaleSchema.parse(req.body);
    const result = await this.service.create(dto);
    return ok(result);
  }

  async recordPayment(req: FastifyRequest) {
    const { id } = saleIdParamSchema.parse(req.params);
    const dto = (await import('./sale.schema')).recordPaymentSchema.parse(req.body);
    const result = await this.service.recordPayment(id, dto);
    return ok(result);
  }

  async update(req: FastifyRequest) {
    const { id } = saleIdParamSchema.parse(req.params);
    const dto = (await import('./sale.schema')).updateSaleSchema.parse(req.body);
    const result = await this.service.update(id, dto);
    return ok(result);
  }
}
