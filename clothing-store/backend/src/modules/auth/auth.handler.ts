import type { FastifyRequest } from 'fastify';
import { ok } from '../../shared/types';
import { AuthService } from './auth.service';
import { loginRequestSchema } from './auth.schema';
import { getJwtPayload } from '../../plugins/auth';

export class AuthHandler {
  constructor(private readonly service: AuthService) {}

  async login(req: FastifyRequest) {
    const dto = loginRequestSchema.parse(req.body);
    const result = await this.service.login(dto);
    return ok(result);
  }

  async me(req: FastifyRequest) {
    const payload = getJwtPayload(req);
    const result = await this.service.me(payload);
    return ok(result);
  }
}
