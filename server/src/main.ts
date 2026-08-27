import { HttpAdapterHost, NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { SQLiteExceptionFilter } from './common/sqlite-exception.filter';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  app.useGlobalFilters(
    new SQLiteExceptionFilter(app.get(HttpAdapterHost).httpAdapter),
  );
  app.enableShutdownHooks();
  app.enableCors({ origin: '*' });
  await app.listen(Bun.env.PORT ?? 3000);
}
bootstrap();
