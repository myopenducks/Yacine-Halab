import { ok } from '../../shared/types';
import { createSaleSchema, saleIdParamSchema, saleListQuerySchema, } from './sale.schema';
export class SaleHandler {
    service;
    constructor(service) {
        this.service = service;
    }
    async list(req) {
        const query = saleListQuerySchema.parse(req.query);
        const result = await this.service.list(query);
        return ok(result);
    }
    async get(req) {
        const { id } = saleIdParamSchema.parse(req.params);
        const result = await this.service.getById(id);
        return ok(result);
    }
    async create(req) {
        const dto = createSaleSchema.parse(req.body);
        const result = await this.service.create(dto);
        return ok(result);
    }
}
//# sourceMappingURL=sale.handler.js.map