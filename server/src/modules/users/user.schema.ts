import { integer, snakeCase, text } from 'drizzle-orm/sqlite-core';
import { ROLES } from '@common/constants';
import { createSelectSchema } from 'drizzle-zod';
import { z } from 'zod';
import { commonColumns } from '@common/helpers/schema.helper';

export const user = snakeCase.table('user', {
  id: commonColumns.id,
  ...commonColumns.timespamps,
  name: text().notNull(),
  email: text().notNull().unique(),
  password_hash: text().notNull(),
  role: text({ enum: ROLES }).notNull().default('employee'),
  isActive: integer({ mode: 'boolean' }).notNull().default(true),
});

export type User = typeof user.$inferSelect;
export type NewUser = typeof user.$inferInsert;

/**
 * The columns every endpoint is allowed to hand back. Passing this to
 * `findMany({ columns })` makes leaking `password_hash` a compile error rather
 * than something you have to remember at each call site.
 */
export const publicUserColumns = {
  id: true,
  name: true,
  email: true,
  role: true,
  isActive: true,
  createdAt: true,
  updatedAt: true,
} as const;

/**
 * The client sends a plaintext `password`; the column is `password_hash`. The
 * DTO deliberately does not mirror the table here — hashing happens in the
 * service, and nothing outside it should be able to set the hash directly.
 */
export const createUserSchema = z.object({
  name: z.string().trim().min(2).max(80),
  email: z.email(),
  password: z.string().min(8).max(128),
  role: z.enum(ROLES).default('employee'),
  isActive: z.boolean().default(true),
});

export const updateUserSchema = createUserSchema.partial();
export const userResponseSchema = createSelectSchema(user).omit({
  password_hash: true,
});

export const listUserQuerySchema = z.object({
  q: z.string().trim().min(1).optional(),
  role: z.enum(ROLES).optional(),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  offset: z.coerce.number().int().min(0).default(0),
});
