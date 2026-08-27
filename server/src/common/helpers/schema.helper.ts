import { sql } from 'drizzle-orm';
import { integer } from 'drizzle-orm/sqlite-core';

export const commonColumns = {
  id: integer().primaryKey({ autoIncrement: true }),
  timespamps: {
    createdAt: integer('created_at', { mode: 'timestamp_ms' }).notNull().default(sql`(unixepoch() * 1000)`),
    updatedAt: integer('updated_at', { mode: 'timestamp_ms' }).notNull()
      .default(sql`(unixepoch() * 1000)`)
      .$onUpdate(() => sql`(unixepoch() * 1000)`),
  },
};
