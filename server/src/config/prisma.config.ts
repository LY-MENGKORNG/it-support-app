import 'dotenv/config';
import { defineConfig } from 'prisma/config';
import { env } from '@config/env.config';

export default defineConfig({
  schema: 'db/schema/',
  migrations: {
    path: 'db/migrations',
  },
  datasource: {
    url: env.DATABASE_URL,
  },
});
