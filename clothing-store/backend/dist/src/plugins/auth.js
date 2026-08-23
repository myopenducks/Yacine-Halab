import { AppError } from '../shared/errors';
export function isJwtPayload(v) {
    if (typeof v !== 'object' || v === null)
        return false;
    const rawSub = v.sub;
    const subNum = typeof rawSub === 'string' ? Number(rawSub) : rawSub;
    return (typeof subNum === 'number' &&
        Number.isFinite(subNum) &&
        typeof v.username === 'string');
}
export function getJwtPayload(req) {
    const stored = req.__jwt;
    if (stored)
        return stored;
    if (isJwtPayload(req.user)) {
        const rawSub = req.user.sub;
        const sub = typeof rawSub === 'string' ? Number(rawSub) : rawSub;
        return { sub, username: req.user.username };
    }
    throw new AppError({
        code: 'UNAUTHORIZED',
        statusCode: 401,
        message: 'Invalid token payload',
    });
}
const PUBLIC_ROUTES = [
    { method: 'GET', url: '/health' },
    { method: 'POST', url: '/api/v1/auth/login' },
];
function stripQuery(url) {
    if (!url)
        return '';
    const idx = url.indexOf('?');
    return idx >= 0 ? url.slice(0, idx) : url;
}
function isPublic(req) {
    const method = (req.method ?? req.raw.method ?? '').toUpperCase();
    const url = stripQuery(req.url ?? req.raw.url ?? '');
    return PUBLIC_ROUTES.some((r) => r.method.toUpperCase() === method && r.url === url);
}
export async function registerAuth(app) {
    app.addHook('onRequest', async (req) => {
        if (isPublic(req))
            return;
        try {
            const decoded = await req.jwtVerify();
            if (!isJwtPayload(decoded)) {
                throw new AppError({
                    code: 'UNAUTHORIZED',
                    statusCode: 401,
                    message: 'Invalid token payload',
                });
            }
            const rawSub = decoded.sub;
            const sub = typeof rawSub === 'string' ? Number(rawSub) : rawSub;
            const normalized = {
                sub,
                username: decoded.username,
            };
            req.__jwt = normalized;
        }
        catch (err) {
            if (err instanceof AppError)
                throw err;
            const msg = typeof err.message === 'string'
                ? err.message
                : 'Authentication required';
            throw new AppError({
                code: 'UNAUTHORIZED',
                statusCode: 401,
                message: msg,
            });
        }
    });
}
//# sourceMappingURL=auth.js.map