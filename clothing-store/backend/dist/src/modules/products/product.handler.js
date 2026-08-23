import { ok } from '../../shared/types';
import { createProductSchema, productIdParamSchema, productListQuerySchema, updateProductSchema, } from './product.schema';
export class ProductHandler {
    service;
    constructor(service) {
        this.service = service;
    }
    async list(req) {
        const query = productListQuerySchema.parse(req.query);
        const result = await this.service.list(query);
        return ok(result);
    }
    async get(req) {
        const { id } = productIdParamSchema.parse(req.params);
        const result = await this.service.getById(id);
        return ok(result);
    }
    async create(req) {
        const dto = createProductSchema.parse(req.body);
        const result = await this.service.create(dto);
        return ok(result);
    }
    async update(req) {
        const { id } = productIdParamSchema.parse(req.params);
        const dto = updateProductSchema.parse(req.body);
        const result = await this.service.update(id, dto);
        return ok(result);
    }
    async delete(req) {
        const { id } = productIdParamSchema.parse(req.params);
        await this.service.delete(id);
        return ok(null);
    }
}
//# sourceMappingURL=product.handler.js.map