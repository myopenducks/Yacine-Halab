import { verify } from 'argon2';
import { AppError } from '../../shared/errors';
function toPublic(u) {
    return { id: u.id, username: u.username };
}
export class AuthService {
    repo;
    fastify;
    constructor(repo, fastify) {
        this.repo = repo;
        this.fastify = fastify;
    }
    async login(dto) {
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
        const payload = {
            sub: String(user.id),
            username: user.username,
        };
        const token = await this.fastify.jwt.sign(payload);
        return { token, user: toPublic(user) };
    }
    async me(payload) {
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
//# sourceMappingURL=auth.service.js.map