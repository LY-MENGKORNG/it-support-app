import { text, integer, index, snakeCase } from 'drizzle-orm/sqlite-core';
import { z } from 'zod';
import { PRIORITY, REQUEST_STATUS } from '../../common/constants';
import { commonColumns } from '@common/helpers/schema.helper';
import { category } from '../categories/category.schema';
import { user } from '../users/user.schema';

export const request = snakeCase.table(
  'request',
  {
    id: commonColumns.id,
    title: text().notNull(),
    description: text().notNull(),
    categoryId: integer()
      .notNull()
      .references(() => category.id),
    priority: text({ enum: PRIORITY }).notNull().default('medium'),
    status: text({ enum: REQUEST_STATUS }).notNull().default('open'),

    requesterId: integer('requester_id')
      .notNull()
      .references(() => user.id),

    assigneeId: integer('assignee_id').references(() => user.id),

    ...commonColumns.timespamps,

    resolvedAt: integer({ mode: 'timestamp_ms' }),
    closedAt: integer({ mode: 'timestamp_ms' }),
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

export type Request = typeof request.$inferSelect;
export type NewRequest = typeof request.$inferInsert;

export const createRequestSchema = z.object({
  title: z.string().trim().min(3).max(120),
  description: z.string().trim().min(1).max(5000),
  categoryId: z.coerce.number().int().positive(),
  priority: z.enum(PRIORITY).default('medium'),
  assigneeId: z.coerce.number().int().positive().nullish(),
});

export const updateRequestSchema = z
  .object({
    title: z.string().trim().min(3).max(120),
    description: z.string().trim().min(1).max(5000),
    categoryId: z.coerce.number().int().positive(),
    priority: z.enum(PRIORITY),
    status: z.enum(REQUEST_STATUS),
    assigneeId: z.coerce.number().int().positive().nullable(),
  })
  .partial()
  .refine((dto) => Object.keys(dto).length > 0, 'No fields to update');

export const listRequestQuerySchema = z.object({
  q: z.string().trim().min(1).optional(),
  status: z.enum(REQUEST_STATUS).optional(),
  priority: z.enum(PRIORITY).optional(),
  categoryId: z.coerce.number().int().positive().optional(),
  requesterId: z.coerce.number().int().positive().optional(),
  assigneeId: z.coerce.number().int().positive().optional(),
  unassigned: z.stringbool().optional(),
  sort: z.enum(['newest', 'oldest', 'priority']).default('newest'),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  offset: z.coerce.number().int().min(0).default(0),
});
