import { drizzle, LibSQLDatabase } from 'drizzle-orm/libsql';
import { type Client, createClient } from '@libsql/client';
import { relations } from './relation.config';
import { env } from '@config/env.config';

export const connection = {
  url: env.TURSO_CONNECTION_URL!,
  authToken: env.TURSO_AUTH_TOKEN!,
} as const;

const client = createClient({
  url: connection.url,
  authToken: connection.authToken,
});

export const db = drizzle({ relations, client, logger: true });

export type DrizzleDB = LibSQLDatabase<typeof relations> & {
  $client: Client;
};
