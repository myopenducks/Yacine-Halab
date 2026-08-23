import { isAppError } from '../shared/errors';
import { fail } from '../shared/types';
const isZodError = (e) => {
    return (typeof e === 'object' &&
        e !== null &&
        e.name === 'ZodError');
};
export async function registerErrorHandling(app) {
    app.setErrorHandler((err, _req, reply) => {
        if (isAppError(err)) {
            return reply
                .status(err.statusCode)
                .send(fail(err.code, err.message, err.details));
        }
        if (isZodError(err)) {
            return reply.status(400).send(fail('VALIDATION_ERROR', 'Request validation failed', {
                issues: err.issues,
            }));
        }
        if (err.statusCode ===
            400 &&
            err.validation) {
            return reply.status(400).send(fail('VALIDATION_ERROR', 'Request validation failed', {
                raw: err.validation,
            }));
        }
        const statusCode = typeof err.statusCode === 'number'
            ? err.statusCode
            : 500;
        app.log.error?.({ err }, 'unhandled error');
        return reply
            .status(statusCode >= 400 && statusCode < 600 ? statusCode : 500)
            .send(fail('INTERNAL_ERROR', statusCode === 500
            ? 'An unexpected error occurred'
            : (err.message ?? 'Request failed')));
    });
    app.setNotFoundHandler((_req, reply) => {
        reply.status(404).send(fail('INTERNAL_ERROR', 'Route not found'));
    });
}
//# sourceMappingURL=error.js.map