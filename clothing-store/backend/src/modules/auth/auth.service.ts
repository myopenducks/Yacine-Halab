import { verify } from 'argon2';
import type { FastifyInstance } from 'fastify';
import { AppError } from '../../shared/errors';
import { AuthRepository } from './auth.repository';
import type {
  LoginRequest,
  LoginResponse,
  MeResponse,
  PublicUser,
} from './auth.schema';
import type { JwtPayload } from '../../plugins/auth';

function toPublic(u: { id: number; username: string }): PublicUser {
  return { id: u.id, username: u.username };
}

export class AuthService {
  constructor(
    private readonly repo: AuthRepository,
    private readonly fastify: FastifyInstance,
  ) {}

  async login(dto: LoginRequest): Promise<LoginResponse> {
    const user = await this.repo.findByUsername(dto.username);
    if (!user) {
      throw new AppError({
        code: 'INVALID_CREDENTIALS',
        statusCode: 401,
        message: 'Invalid username or password',
      });
    }

    const valid = await verify(user.passwordHash, dto.password);
    if (!valid) {
      throw new AppError({
        code: 'INVALID_CREDENTIALS',
        statusCode: 401,
        message: 'Invalid username or password',
      });
    }

    const payload: { sub: string; username: string } = {
      sub: String(user.id),
      username: user.username,
    };
    const token = await this.fastify.jwt.sign(payload);

    return { token, user: toPublic(user) };
  }

  async me(payload: JwtPayload): Promise<MeResponse> {
    const user = await this.repo.findById(payload.sub);
    if (!user) {
      throw new AppError({
        code: 'UNAUTHORIZED',
        statusCode: 401,
        message: 'User not found',
      });
    }
    return toPublic(user);
  }
}
