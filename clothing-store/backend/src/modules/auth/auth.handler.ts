import type { FastifyRequest } from 'fastify';
import { ok } from '../../shared/types';
import { AuthService } from './auth.service';
import { changePasswordSchema, loginRequestSchema, registerRequestSchema } from './auth.schema';
import { getJwtPayload } from '../../plugins/auth';

export class AuthHandler {
  constructor(private readonly service: AuthService) {}

  async login(req: FastifyRequest) {
    const dto = loginRequestSchema.parse(req.body);
    const result = await this.service.login(dto);
    return ok(result);
  }

  async register(req: FastifyRequest) {
    const dto = registerRequestSchema.parse(req.body);
    const result = await this.service.register(dto);
    return ok(result);
  }

  async guest(_req: FastifyRequest) {
    const result = await this.service.guest();
    return ok(result);
  }

  async changePassword(req: FastifyRequest) {
    const payload = getJwtPayload(req);
    const dto = changePasswordSchema.parse(req.body);
    const result = await this.service.changePassword(Number(payload.sub), dto);
    return ok(result);
  }

  async me(req: FastifyRequest) {
    const payload = getJwtPayload(req);
    const result = await this.service.me(payload);
    return ok(result);
  }
}
