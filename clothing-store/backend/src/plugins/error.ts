import type { FastifyInstance, FastifyReply } from 'fastify';
import { isAppError } from '../shared/errors';
import type { ZodError } from 'zod';
import { fail } from '../shared/types';

const isZodError = (e: unknown): e is ZodError => {
  return (
    typeof e === 'object' &&
    e !== null &&
    (e as { name?: string }).name === 'ZodError'
  );
};

export async function registerErrorHandling(app: FastifyInstance): Promise<void> {
  app.setErrorHandler((err, _req, reply: FastifyReply) => {
    if (isAppError(err)) {
      return reply
        .status(err.statusCode)
        .send(fail(err.code, err.message, err.details));
    }

    if (isZodError(err)) {
      return reply.status(400).send(
        fail('VALIDATION_ERROR', 'Request validation failed', {
          issues: err.issues,
        }),
      );
    }

    if (
      (err as { statusCode?: number; validation?: unknown }).statusCode ===
        400 &&
      (err as { validation?: unknown }).validation
    ) {
      return reply.status(400).send(
        fail('VALIDATION_ERROR', 'Request validation failed', {
          raw: (err as { validation?: unknown }).validation,
        }),
      );
    }

    const statusCode =
      typeof (err as { statusCode?: number }).statusCode === 'number'
        ? ((err as { statusCode: number }).statusCode as number)
        : 500;

    app.log.error?.({ err }, 'unhandled error');

    return reply
      .status(statusCode >= 400 && statusCode < 600 ? statusCode : 500)
      .send(
        fail(
          'INTERNAL_ERROR',
          statusCode === 500
            ? 'An unexpected error occurred'
            : (err.message ?? 'Request failed'),
        ),
      );
  });

  app.setNotFoundHandler((_req, reply) => {
    reply.status(404).send(fail('INTERNAL_ERROR', 'Route not found'));
  });
}
