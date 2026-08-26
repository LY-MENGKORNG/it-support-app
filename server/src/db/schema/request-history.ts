import { index, integer, snakeCase, text } from 'drizzle-orm/sqlite-core';
import { commonColumns } from '../utils/helper';
import { request } from './request';
import { user } from './user';
import { sql } from 'drizzle-orm';
import { REQUEST_HISTORY_STATUS } from '../../common/constants';

export const requestHistory = snakeCase.table(
  'request_history',
  {
    id: commonColumns.id,
    requestId: integer().notNull().references(() => request.id, { onDelete: 'cascade' }),
    userId: integer().notNull().references(() => user.id),
    action: text({ enum: REQUEST_HISTORY_STATUS }).notNull(),
    oldValue: text(),
    newValue: text(),
    createdAt: integer({ mode: 'timestamp' }).notNull().default(sql`(unixepoch())`),
  },
  (table) => [
    index('request_history_request_idx').on(table.requestId),
    index('request_history_user_idx').on(table.userId),
    index('request_history_created_at_idx').on(table.createdAt),
  ],
);
