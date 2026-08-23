import type { FastifyRequest } from 'fastify';
import { ok } from '../../shared/types';
import { DashboardService } from './dashboard.service';
import { salesQuerySchema, summaryQuerySchema } from './dashboard.schema';

export class DashboardHandler {
  constructor(private readonly service: DashboardService) {}

  async summary(req: FastifyRequest) {
    const query = summaryQuerySchema.parse(req.query);
    const result = await this.service.summary(query);
    return ok(result);
  }

  async sales(req: FastifyRequest) {
    const query = salesQuerySchema.parse(req.query);
    const result = await this.service.salesChart(query);
    return ok(result);
  }
}
