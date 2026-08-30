import { Database } from 'bun:sqlite';
import { drizzle, SQLiteBunDatabase } from 'drizzle-orm/bun-sqlite';
import { relations } from './relation.config';

const client = new Database('db.sqlite');

client.run('PRAGMA journal_mode = WAL;'); // concurrent readers
client.run('PRAGMA foreign_keys = ON;'); // OFF by default in SQLite
client.run('PRAGMA busy_timeout = 5000;'); // avoid SQLITE_BUSY throws
client.run('PRAGMA synchronous = NORMAL;'); // safe with WAL

export const db = drizzle({ client, relations });

export type DrizzleDB = SQLiteBunDatabase<typeof relations> & {
  $client: Database;
};
