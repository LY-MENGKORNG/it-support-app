import { HttpAdapterHost, NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { SQLiteExceptionFilter } from './common/sqlite-exception.filter';
import { apiReference } from '@config/docs.config';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  app.useGlobalFilters(
    new SQLiteExceptionFilter(app.get(HttpAdapterHost).httpAdapter),
  );
  app.enableShutdownHooks();
  app.enableCors({ origin: '*' });
  app.use('/api', apiReference(app));

  await app.listen(Bun.env.PORT ?? 3000);
}
bootstrap();
