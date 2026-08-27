import { sqliteTable, text } from 'drizzle-orm/sqlite-core';
import { commonColumns } from 'src/common/helpers/schema.helper';

export const category = sqliteTable('category', {
  id: commonColumns.id,
  name: text('name').notNull().unique(),
  description: text('description'),
  createdAt: commonColumns.timespamps.createdAt,
});

export type Category = typeof category.$inferSelect;
export type NewCategory = typeof category.$inferInsert;
