import { Module } from '@nestjs/common';
import { UserModule } from './modules/users/user.module';
import { ConfigModule } from '@nestjs/config';
import { envSchema } from './config/env.config';
import { DBModule } from './modules/db/db.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      cache: true,
      ignoreEnvFile: true,
      validate: (raw) => envSchema.parse(raw)
    }),
    UserModule,
    DBModule
  ],
  controllers: [],
  providers: [],
})
export class AppModule { }
