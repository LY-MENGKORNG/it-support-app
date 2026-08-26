import { text, integer, index, snakeCase } from 'drizzle-orm/sqlite-core';
import { commonColumns } from '../utils/helper';
import { user } from './user';
import { category } from './category';
import { PRIORITY, REQUEST_STATUS } from '../../common/constants';

export const request = snakeCase.table(
  'request',
  {
    id: commonColumns.id,
    title: text().notNull(),
    description: text().notNull(),
    categoryId: integer().notNull().references(() => category.id),
    priority: text({ enum: PRIORITY }).notNull().default('medium'),
    status: text({ enum: REQUEST_STATUS }).notNull().default('open'),

    /**
     * Employee who created the request.
     */
    requesterId: integer('requester_id')
      .notNull()
      .references(() => user.id),

    /**
     * IT staff currently assigned to the request.
     *
     * Nullable because a request can be unassigned.
     */
    assigneeId: integer('assignee_id').references(() => user.id),

    ...commonColumns.timespamps,

    resolvedAt: integer({ mode: 'timestamp' }),
    closedAt: integer({ mode: 'timestamp' }),
  },
  (table) => [
    index('request_requester_idx').on(table.requesterId),
    index('request_assignee_idx').on(table.assigneeId),
    index('request_category_idx').on(table.categoryId),
    index('request_status_idx').on(table.status),
    index('request_priority_idx').on(table.priority),
    index('request_created_at_idx').on(table.createdAt),
  ],
);
