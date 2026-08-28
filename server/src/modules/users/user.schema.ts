import { integer, snakeCase, text } from 'drizzle-orm/sqlite-core';
import { ROLES } from '../../common/constants';
import { createInsertSchema, createSelectSchema } from 'drizzle-zod';
import { z } from 'zod';
import { commonColumns } from 'src/common/helpers/schema.helper';

export const user = snakeCase.table('user', {
  id: commonColumns.id,
  ...commonColumns.timespamps,
  name: text().notNull(),
  email: text().notNull().unique(),
  password_hash: text().notNull(),
  role: text({ enum: ROLES }).default('employee'),
  isActive: integer({ mode: 'boolean' }).notNull().default(true),
});

export const createUserSchema = createInsertSchema(user)
  .omit({ id: true, createdAt: true })
  .extend({ email: z.email() });

export const updateUserSchema = createUserSchema.partial();
export const userResponseSchema = createSelectSchema(user);

export type CreateUserDto = z.infer<typeof createUserSchema>;
export type UpdateUserDto = z.infer<typeof updateUserSchema>;
