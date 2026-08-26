import { sqliteTable, text } from 'drizzle-orm/sqlite-core';
import { commonColumns } from '../utils/helper';

export const category = sqliteTable('category', {
  id: commonColumns.id,
  name: text('name').notNull().unique(),
  description: text('description'),
  createdAt: commonColumns.timespamps.createdAt,
});
