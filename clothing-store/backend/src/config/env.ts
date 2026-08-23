import { z } from 'zod';
import { applyPlatformEnvDefaults } from './platform-env';

const WEAK_JWT_MARKERS = [
  'replace-this-with-a-long-random-string',
  'changeme',
  'your-secret',
  'jwt_secret',
  'please',
] as const;

const envSchema = z
  .object({
    NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
    PORT: z.coerce.number().int().min(1).max(65535).default(3000),
    HOST: z.string().default('0.0.0.0'),

    DB_HOST: z.string().default('127.0.0.1'),
    DB_PORT: z.coerce.number().int().min(1).max(65535).default(3306),
    DB_USER: z.string().default('root'),
    DB_PASSWORD: z.string().default(''),
    DB_NAME: z.string().default('clothing_store'),

    JWT_SECRET: z.string().min(16),
    JWT_EXPIRES_IN: z.string().default('7d'),

    CORS_ORIGIN: z.string().default('*'),
  })
  .superRefine((data, ctx) => {
    const lower = data.JWT_SECRET.toLowerCase();
    const looksWeak =
      data.JWT_SECRET.length < 32 ||
      WEAK_JWT_MARKERS.some((m) => lower.includes(m));

    if (data.NODE_ENV === 'production' && looksWeak) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ['JWT_SECRET'],
        message:
          'JWT_SECRET must be at least 32 random characters and not a placeholder in production',
      });
    }
  });

export type Env = z.infer<typeof envSchema>;

let cached: Env | null = null;

export function loadEnv(): Env {
  if (cached) return cached;
  applyPlatformEnvDefaults();
  cached = envSchema.parse(process.env);
  warnIfWeakJwtSecret(cached);
  return cached;
}

export function warnIfWeakJwtSecret(env: Env): void {
  if (env.NODE_ENV === 'production') return;
  const lower = env.JWT_SECRET.toLowerCase();
  const weak =
    env.JWT_SECRET.length < 32 ||
    WEAK_JWT_MARKERS.some((m) => lower.includes(m));
  if (weak) {
    console.warn(
      '[security] JWT_SECRET is weak or a placeholder — fine for local dev, set a strong random value before production.',
    );
  }
}
