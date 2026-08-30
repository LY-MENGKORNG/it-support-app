import { index, integer, snakeCase, text } from 'drizzle-orm/sqlite-core';
import { sql } from 'drizzle-orm';
import { REQUEST_HISTORY_STATUS } from '../../common/constants';
import { commonColumns } from 'src/common/helpers/schema.helper';
import { request } from '../requests/request.schema';
import { user } from '../users/user.schema';

export const requestHistory = snakeCase.table(
  'request_history',
  {
    id: commonColumns.id,
    requestId: integer()
      .notNull()
      .references(() => request.id, { onDelete: 'cascade' }),
    userId: integer()
      .notNull()
      .references(() => user.id),
    action: text({ enum: REQUEST_HISTORY_STATUS }).notNull(),
    oldValue: text(),
    newValue: text(),
    createdAt: integer({ mode: 'timestamp_ms' })
      .notNull()
      .default(sql`(unixepoch() * 1000)`),
  },
  (table) => [
    index('request_history_request_idx').on(table.requestId),
    index('request_history_user_idx').on(table.userId),
    index('request_history_created_at_idx').on(table.createdAt),
  ],
);

export type RequestHistory = typeof requestHistory.$inferSelect;
export type NewRequestHistory = typeof requestHistory.$inferInsert;

/**
 * A history row before it knows which request it belongs to.
 *
 * `RequestService` computes these from a diff, and `RequestRepository` writes
 * them alongside the change itself — so the two can never disagree.
 */
export type RequestHistoryDraft = Omit<
  NewRequestHistory,
  'id' | 'requestId' | 'createdAt'
>;
