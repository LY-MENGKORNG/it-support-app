import { index, integer, sqliteTable, text } from "drizzle-orm/sqlite-core";
import { commonColumns } from "../utils/helper";
import { request } from "./request";
import { user } from "./user";
import { sql } from "drizzle-orm";
import { REQUEST_HISTORY_STATUS } from "../../constants";

export const requestHistory = sqliteTable(
  "request_history",
  {
    id: commonColumns.id,

    requestId: integer("request_id")
      .notNull()
      .references(() => request.id, {
        onDelete: "cascade",
      }),

    userId: integer("user_id")
      .notNull()
      .references(() => user.id),

    action: text("action", { enum: REQUEST_HISTORY_STATUS }).notNull(),

    oldValue: text("old_value"),

    newValue: text("new_value"),

    createdAt: integer("created_at", {
      mode: "timestamp",
    })
      .notNull()
      .default(sql`(unixepoch())`),
  },
  (table) => [
    index("request_history_request_idx").on(
      table.requestId,
    ),

    index("request_history_user_idx").on(
      table.userId,
    ),

    index("request_history_created_at_idx").on(
      table.createdAt,
    ),
  ],
);
