import { z } from 'zod';
import { ROLES, type Role } from '@common/constants';
import { userResponseSchema } from '../users/user.schema';

/**
 * Credentials, deliberately looser than the password rule in
 * `createUserSchema`: a login form must not advertise the password policy, and
 * rejecting a short password here would leak that a longer one is required.
 */
export const loginSchema = z.object({
  email: z.email(),
  password: z.string().min(1).max(128),
});

/** What a successful login hands back: the token, and who it belongs to. */
export const sessionResponseSchema = z.object({
  accessToken: z.string(),
  user: userResponseSchema,
});

export type LoginDto = z.infer<typeof loginSchema>;

/**
 * The signed part of the token.
 *
 * `sub` is the user id, per the JWT spec's "subject" claim. The role rides
 * along so an authorisation check costs no database round trip — the trade is
 * that a role change only takes effect once the old token expires, which is
 * the usual bargain with stateless tokens.
 */
export type AccessTokenPayload = {
  sub: number;
  email: string;
  role: Role;
};

export const accessTokenPayloadSchema = z.object({
  sub: z.number().int().positive(),
  email: z.string(),
  role: z.enum(ROLES),
});

/**
 * The caller, as every guarded handler sees them.
 *
 * Deliberately not a `User` row: it carries only what the token proved, so no
 * handler can mistake a claim for freshly-read database state.
 */
export type AuthenticatedUser = {
  id: number;
  email: string;
  role: Role;
};
