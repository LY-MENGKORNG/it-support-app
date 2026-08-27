import { index, integer, text, snakeCase } from 'drizzle-orm/sqlite-core';
import { sql } from 'drizzle-orm';
import { commonColumns } from 'src/common/helpers/schema.helper';
import { request } from '../requests/request.schema';
import { user } from '../users/user.schema';

export const comment = snakeCase.table(
  'comment',
  {
    id: commonColumns.id,
    requestId: integer().notNull().references(() => request.id, { onDelete: 'cascade' }),
    userId: integer().notNull().references(() => user.id),
    content: text().notNull(),
    createdAt: integer({ mode: 'timestamp' }).notNull().default(sql`(unixepoch())`),
    updatedAt: integer({ mode: 'timestamp' }),
  },
  (table) => [
    index('comments_request_idx').on(table.requestId),
    index('comments_user_idx').on(table.userId),
  ],
);

export type Comment = typeof comment.$inferSelect;
export type NewComment = typeof comment.$inferInsert;
