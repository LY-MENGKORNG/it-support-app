import { z } from 'zod';

export const envSchema = z
  .object({
    NODE_ENV: z
      .enum(['development', 'test', 'production'])
      .default('development')
      .readonly(),
    PORT: z.coerce.number().int().positive().default(3000).readonly(),

    /**
     * The HMAC key every access token is signed with. Changing it invalidates
     * every issued token, which is exactly what you want after a leak.
     *
     * A default is fine for local work but must not ship: the refinement below
     * makes production fail to boot rather than sign tokens with a value that
     * is printed in this repository.
     */
    JWT_SECRET: z
      .string()
      .min(16)
      .default('dev-only-insecure-jwt-secret-key')
      .readonly(),

    /** Any `ms` duration. Short enough to matter, long enough to be usable. */
    JWT_EXPIRES_IN: z.string().default('7d').readonly(),
  })
  .loose()
  .refine(
    (env) =>
      env.NODE_ENV !== 'production' ||
      env.JWT_SECRET !== 'dev-only-insecure-jwt-secret-key',
    { path: ['JWT_SECRET'], message: 'JWT_SECRET must be set in production' },
  );

export type Env = z.infer<typeof envSchema>;
