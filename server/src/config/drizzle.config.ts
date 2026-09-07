import { defineConfig } from 'drizzle-kit';
import { connection as dbCredentials } from './db';

export default defineConfig({
  out: 'src/modules/db/migrations',
  schema: 'src/modules/*/*.schema.ts',
  dialect: 'turso',
  dbCredentials,
  strict: true,
});
