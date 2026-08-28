import type { FastifyRequest } from 'fastify';
import { ok } from '../../shared/types';
import { DashboardService } from './dashboard.service';
import { salesQuerySchema, summaryQuerySchema } from './dashboard.schema';

export class DashboardHandler {
  constructor(private readonly service: DashboardService) {}

  async summary(req: FastifyRequest) {
    const userId = (req.user as { id: number }).id;
    const query = summaryQuerySchema.parse(req.query);
    const result = await this.service.summary(query, userId);
    return ok(result);
  }

  async sales(req: FastifyRequest) {
    const userId = (req.user as { id: number }).id;
    const query = salesQuerySchema.parse(req.query);
    const result = await this.service.salesChart(query, userId);
    return ok(result);
  }

  async soldItems(req: FastifyRequest) {
    const userId = (req.user as { id: number }).id;
    const query = summaryQuerySchema.parse(req.query);
    const result = await this.service.soldItems(query, userId);
    return ok(result);
  }
}
