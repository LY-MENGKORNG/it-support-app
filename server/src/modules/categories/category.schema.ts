import { sqliteTable, text } from 'drizzle-orm/sqlite-core';
import { z } from 'zod';
import { commonColumns } from 'src/common/helpers/schema.helper';

export const category = sqliteTable('category', {
  id: commonColumns.id,
  name: text('name').notNull().unique(),
  description: text('description'),
  createdAt: commonColumns.timespamps.createdAt,
});

export type Category = typeof category.$inferSelect;
export type NewCategory = typeof category.$inferInsert;

export const createCategorySchema = z.object({
  name: z.string().trim().min(2).max(60),
  description: z.string().trim().max(500).nullish(),
});
