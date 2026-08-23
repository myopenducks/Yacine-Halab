import { ok } from '../../shared/types';
export class CategoryHandler {
    service;
    constructor(service) {
        this.service = service;
    }
    async list() {
        const result = await this.service.list();
        return ok(result);
    }
}
//# sourceMappingURL=category.handler.js.map