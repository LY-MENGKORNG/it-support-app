import { sqliteTable, text, integer, index } from "drizzle-orm/sqlite-core";
import { commonColumns } from "../utils/helper";
import { user } from "./user";
import { category } from "./category";
import { PRIORITY, REQUEST_STATUS } from "../../constants";

export const request = sqliteTable(
  "request",
  {
    id: commonColumns.id,
    title: text("title").notNull(),

    description: text("description").notNull(),

    categoryId: integer("category_id")
      .notNull()
      .references(() => category.id),

    priority: text("priority", { enum: PRIORITY })
      .notNull()
      .default("medium"),

    status: text("status", {
      enum: REQUEST_STATUS
    })
      .notNull()
      .default("open"),

    /**
     * Employee who created the request.
     */
    requesterId: integer("requester_id")
      .notNull()
      .references(() => user.id),

    /**
     * IT staff currently assigned to the request.
     *
     * Nullable because a request can be unassigned.
     */
    assigneeId: integer("assignee_id").references(
      () => user.id,
    ),

    ...commonColumns.timespamps,

    resolvedAt: integer("resolved_at", {
      mode: "timestamp",
    }),

    closedAt: integer("closed_at", {
      mode: "timestamp",
    }),
  },
  (table) => [
    index("request_requester_idx").on(
      table.requesterId,
    ),

    index("request_assignee_idx").on(
      table.assigneeId,
    ),

    index("request_category_idx").on(
      table.categoryId,
    ),

    index("request_status_idx").on(
      table.status,
    ),

    index("request_priority_idx").on(
      table.priority,
    ),

    index("request_created_at_idx").on(
      table.createdAt,
    ),
  ],
);
