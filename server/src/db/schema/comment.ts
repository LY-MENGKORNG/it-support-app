import { sqliteTable, index, integer, text } from "drizzle-orm/sqlite-core";
import { sql } from "drizzle-orm"
import { commonColumns } from "../utils/helper";
import { request } from "./request";
import { user } from "./user";

export const comment = sqliteTable(
  "comment",
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

    content: text("content").notNull(),

    createdAt: integer("created_at", { mode: "timestamp" })
      .notNull()
      .default(sql`(unixepoch())`),

    updatedAt: integer("updated_at", { mode: "timestamp" }),
  },
  (table) => [
    index("comments_request_idx").on(table.requestId),
    index("comments_user_idx").on(table.userId),
  ],
);
