import { ok } from '../../shared/types';
import { salesQuerySchema, summaryQuerySchema } from './dashboard.schema';
export class DashboardHandler {
    service;
    constructor(service) {
        this.service = service;
    }
    async summary(req) {
        const query = summaryQuerySchema.parse(req.query);
        const result = await this.service.summary(query);
        return ok(result);
    }
    async sales(req) {
        const query = salesQuerySchema.parse(req.query);
        const result = await this.service.salesChart(query);
        return ok(result);
    }
}
//# sourceMappingURL=dashboard.handler.js.map