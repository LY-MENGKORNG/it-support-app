import { Global, Inject, Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { DRIZZLE } from 'src/common/constants';
import { db, type DrizzleDB } from '@config/db/db.config';

@Global()
@Module({
  imports: [ConfigModule],
  controllers: [],
  providers: [
    {
      provide: DRIZZLE,
      inject: [ConfigService],
      useFactory: (_config: ConfigService): DrizzleDB => db,
    },
  ],
  exports: [DRIZZLE],
})
export class DBModule {
  constructor(@Inject(DRIZZLE) private readonly db: DrizzleDB) {}

  onApplicationShutdown() {
    this.db.$client.close();
  }
}
