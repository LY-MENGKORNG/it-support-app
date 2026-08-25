import { integer, sqliteTable, text } from "drizzle-orm/sqlite-core";
import { commonColumns } from "../utils/helper";
import { ROLES } from "../../constants";

export const user = sqliteTable("user", {
  id: commonColumns.id,
  ...commonColumns.timespamps,
  name: text().notNull(),
  email: text().notNull().unique(),
  password_hash: text().notNull(),
  role: text("role", { enum: ROLES }).notNull().default("employee"),
  isActive: integer("is_active", { mode: "boolean" }).notNull().default(true),
});
