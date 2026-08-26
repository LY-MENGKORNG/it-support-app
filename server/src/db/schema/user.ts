import { integer, snakeCase, text } from 'drizzle-orm/sqlite-core';
import { commonColumns } from '../utils/helper';
import { ROLES } from '../../common/constants';

export const user = snakeCase.table('user', {
  id: commonColumns.id,
  ...commonColumns.timespamps,
  name: text().notNull(),
  email: text().notNull().unique(),
  password_hash: text().notNull(),
  role: text({ enum: ROLES }).notNull().default('employee'),
  isActive: integer({ mode: 'boolean' }).notNull().default(true),
});
