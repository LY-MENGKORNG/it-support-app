import { text, integer, index, snakeCase } from 'drizzle-orm/sqlite-core';
import { z } from 'zod';
import { PRIORITY, REQUEST_STATUS } from '../../common/constants';
import { commonColumns } from 'src/common/helpers/schema.helper';
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

    /**
     * Stamped when `status` first becomes `resolved` / `closed`, cleared when the
     * request is reopened. Same unit as the other timestamps (`timestamp_ms`) so
     * every date on the wire serialises identically.
     */
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

/**
 * Neither `requesterId` nor `actorId` appears on a write DTO any more.
 *
 * Every mutation is recorded in `request_history`, so those rows still need to
 * know who did it — but the answer now comes from the verified access token
 * rather than from the body. A field a client can type is a field a client can
 * lie about, and "who did this" is exactly the claim that must not be
 * forgeable.
 */
export const createRequestSchema = z.object({
  title: z.string().trim().min(3).max(120),
  description: z.string().trim().min(1).max(5000),
  categoryId: z.coerce.number().int().positive(),
  priority: z.enum(PRIORITY).default('medium'),
  assigneeId: z.coerce.number().int().positive().nullish(),
});

/**
 * Every field optional — a PATCH may carry one key or several. `assigneeId` is
 * explicitly nullable: sending `null` unassigns, omitting it leaves it alone.
 */
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

/**
 * Query string values arrive as strings, so every non-string field is coerced.
 * `q` searches title + description.
 */
export const listRequestQuerySchema = z.object({
  q: z.string().trim().min(1).optional(),
  status: z.enum(REQUEST_STATUS).optional(),
  priority: z.enum(PRIORITY).optional(),
  categoryId: z.coerce.number().int().positive().optional(),
  requesterId: z.coerce.number().int().positive().optional(),
  assigneeId: z.coerce.number().int().positive().optional(),
  /** `true` = only unassigned requests. Takes precedence over `assigneeId`. */
  unassigned: z.stringbool().optional(),
  sort: z.enum(['newest', 'oldest', 'priority']).default('newest'),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  offset: z.coerce.number().int().min(0).default(0),
});
