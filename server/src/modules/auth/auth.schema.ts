import { z } from 'zod';
import { ROLES, type Role } from '@common/constants';
import { userResponseSchema } from '../users/user.schema';

export const loginSchema = z.object({
  email: z.email(),
  password: z.string().min(1).max(128),
});

export const sessionResponseSchema = z.object({
  accessToken: z.string(),
  user: userResponseSchema,
});

export type LoginDto = z.infer<typeof loginSchema>;

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

export type AuthenticatedUser = {
  id: number;
  email: string;
  role: Role;
};
