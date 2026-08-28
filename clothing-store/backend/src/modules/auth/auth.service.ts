import { hash, verify } from 'argon2';
import type { FastifyInstance } from 'fastify';
import { AppError } from '../../shared/errors';
import { AuthRepository } from './auth.repository';
import type {
  ChangePasswordRequest,
  LoginRequest,
  LoginResponse,
  MeResponse,
  PublicUser,
  RegisterRequest,
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
    if (dto.username.toLowerCase() === 'guest' || dto.username.toLowerCase().startsWith('guest_')) {
      return this.guest();
    }

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

  async register(dto: RegisterRequest): Promise<LoginResponse> {
    const existing = await this.repo.findByUsername(dto.username);
    if (existing) {
      throw new AppError({
        code: 'USER_EXISTS',
        statusCode: 409,
        message: 'Username already exists',
      });
    }

    const passwordHash = await hash(dto.password);
    const user = await this.repo.create(dto.username, passwordHash);

    const payload: { sub: string; username: string } = {
      sub: String(user.id),
      username: user.username,
    };
    const token = await this.fastify.jwt.sign(payload);

    return { token, user: toPublic(user) };
  }

  async changePassword(userId: number, dto: ChangePasswordRequest): Promise<{ success: boolean; message: string }> {
    const user = await this.repo.findById(userId);
    if (!user) {
      throw new AppError({
        code: 'USER_NOT_FOUND',
        statusCode: 404,
        message: 'User not found',
      });
    }

    const valid = await verify(user.passwordHash, dto.currentPassword);
    if (!valid) {
      throw new AppError({
        code: 'INVALID_CREDENTIALS',
        statusCode: 400,
        message: 'Current password is incorrect',
      });
    }

    const newHash = await hash(dto.newPassword);
    await this.repo.updatePassword(userId, newHash);

    return { success: true, message: 'Password changed successfully' };
  }

  async guest(): Promise<LoginResponse> {
    const user = await this.repo.createGuest();
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

