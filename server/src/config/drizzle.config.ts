import { defineConfig } from 'drizzle-kit';

export default defineConfig({
  out: 'src/modules/db/migrations',
  schema: 'src/modules/*/*.schema.ts',
  dialect: 'sqlite',
  dbCredentials: { url: Bun.env.DATABASE_URL! },
  strict: true,
});
