import { ok } from '../../shared/types';
import { loginRequestSchema } from './auth.schema';
import { getJwtPayload } from '../../plugins/auth';
export class AuthHandler {
    service;
    constructor(service) {
        this.service = service;
    }
    async login(req) {
        const dto = loginRequestSchema.parse(req.body);
        const result = await this.service.login(dto);
        return ok(result);
    }
    async me(req) {
        const payload = getJwtPayload(req);
        const result = await this.service.me(payload);
        return ok(result);
    }
}
//# sourceMappingURL=auth.handler.js.map