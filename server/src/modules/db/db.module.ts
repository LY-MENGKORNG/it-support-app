import { Global, Inject, Module } from '@nestjs/common';
import { relations, type Relations } from './db.relation';
import { Database } from 'bun:sqlite';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { drizzle, SQLiteBunDatabase } from 'drizzle-orm/bun-sqlite';
import { DRIZZLE } from 'src/common/constants';

export type DrizzleDB = SQLiteBunDatabase<Relations> & { $client: Database };

@Global()
@Module({
  imports: [ConfigModule],
  controllers: [],
  providers: [
    {
      provide: DRIZZLE,
      inject: [ConfigService],
      useFactory: (_config: ConfigService): DrizzleDB => {
        const client = new Database("db.sqlite");

        client.run('PRAGMA journal_mode = WAL;'); // concurrent readers
        client.run('PRAGMA foreign_keys = ON;'); // OFF by default in SQLite
        client.run('PRAGMA busy_timeout = 5000;'); // avoid SQLITE_BUSY throws
        client.run('PRAGMA synchronous = NORMAL;'); // safe with WAL

        return drizzle({ client, relations });
      },
    },
  ],
  exports: [DRIZZLE],
})
export class DBModule {
  constructor(@Inject(DRIZZLE) private readonly db: DrizzleDB) { }

  onApplicationShutdown() {
    this.db.$client.close();
  }
}
