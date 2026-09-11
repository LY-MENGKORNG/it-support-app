import { Global, Inject, Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { DRIZZLE } from '@common/constants';
import { db, type DrizzleDB } from '@config/db';
import { safeTry } from '@common/utils/exception';

@Global()
@Module({
  imports: [ConfigModule],
  controllers: [],
  providers: [
    {
      provide: DRIZZLE,
      inject: [ConfigService],
      useFactory: (_config: ConfigService) => db,
    },
  ],
  exports: [DRIZZLE],
})
export class DBModule {
  constructor(@Inject(DRIZZLE) private readonly db: DrizzleDB) {}

  onApplicationShutdown() {
    safeTry(() => this.db.$client.close());
  }
}
