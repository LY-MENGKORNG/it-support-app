import { z } from 'zod';

export const envSchema = z
  .object({
    /** Nodejs runime environment 🚜 */
    NODE_ENV: z
      .enum(['development', 'test', 'production'])
      .default('development')
      .readonly(),

    /** The running port 🚪 */
    PORT: z.coerce.number().int().positive().default(3000).readonly(),

    /** Database connection string 🔌 */
    DATABASE_URL: z.string().readonly(),

    /** The secret for JSON Web Token 🔐 */
    JWT_SECRET: z
      .string()
      .min(16)
      .default('dev-only-insecure-jwt-secret-key')
      .readonly(),

    /** The number of days for JWT expiration 🌁 */
    JWT_EXPIRES_IN: z.string().default('7d').readonly(),
  })
  .loose()
  .refine(
    (env) =>
      env.NODE_ENV !== 'production' ||
      env.JWT_SECRET !== 'dev-only-insecure-jwt-secret-key',
    { path: ['JWT_SECRET'], message: 'JWT_SECRET must be set in production' },
  );

/**
 * The typesafe loaded env ⚙️
 */
export const env = Bun.env as Readonly<Env>;

export type Env = z.infer<typeof envSchema>;
