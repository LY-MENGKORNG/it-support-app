import { MiddlewareConsumer, Module, type NestModule } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { RequestLoggerMiddleware } from './common/request-logger.middleware';
import { envSchema } from './config/env.config';
import { DBModule } from './modules/db/db.module';
import { AuthModule } from './modules/auth/auth.module';
import { CategoryModule } from './modules/categories/category.module';
import { CommentModule } from './modules/comments/comment.module';
import { RequestHistoryModule } from './modules/request-histories/request-history.module';
import { RequestModule } from './modules/requests/request.module';
import { UserModule } from './modules/users/user.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      cache: true,
      ignoreEnvFile: true,
      validate: (raw) => envSchema.parse(raw),
    }),
    DBModule,
    // Registers the global AuthGuard, so importing it is what makes every other
    // module's routes require a token.
    AuthModule,
    UserModule,
    CategoryModule,
    RequestModule,
    CommentModule,
    RequestHistoryModule,
  ],
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer) {
    consumer.apply(RequestLoggerMiddleware).forRoutes('*splat');
  }
}
