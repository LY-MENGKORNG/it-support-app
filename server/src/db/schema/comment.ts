import { index, integer, text, snakeCase } from 'drizzle-orm/sqlite-core';
import { sql } from 'drizzle-orm';
import { commonColumns } from '../utils/helper';
import { request } from './request';
import { user } from './user';

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
