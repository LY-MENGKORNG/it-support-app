import { Global, Inject, Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { PRISMA } from '@common/constants';
import { db, type PrismaDB } from '@config/db';
import { safeTry } from '@common/utils/exception';

@Global()
@Module({
  imports: [ConfigModule],
  controllers: [],
  providers: [
    {
      provide: PRISMA,
      inject: [ConfigService],
      useFactory: (_config: ConfigService) => db,
    },
  ],
  exports: [PRISMA],
})
export class DBModule {
  constructor(@Inject(PRISMA) private readonly db: PrismaDB) {}

  async onApplicationShutdown() {
    await safeTry(() => this.db.$disconnect());
  }
}
