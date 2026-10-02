import { HttpAdapterHost, NestFactory } from '@nestjs/core';
import {
  FastifyAdapter,
  type NestFastifyApplication,
} from '@nestjs/platform-fastify';
import { AppModule } from './app.module';
import { PrismaExceptionFilter } from './common/prisma-exception.filter';
import { apiReference } from '@config/docs.config';
import { env } from '@config/env.config';

async function bootstrap() {
  const app = await NestFactory.create<NestFastifyApplication>(
    AppModule,
    new FastifyAdapter(),
    {
      snapshot: true
    }
  );

  app.useGlobalFilters(
    new PrismaExceptionFilter(app.get(HttpAdapterHost).httpAdapter),
  );
  app.enableShutdownHooks();
  app.enableCors({ origin: '*' });

  const scalarHandler = apiReference(app);

  app
    .getHttpAdapter()
    .getInstance()
    .get('/api', (request, reply) => {
      reply.hijack();
      scalarHandler(request, reply.raw);
    });

  await app.listen(env.PORT, '0.0.0.0');
}

bootstrap().catch((error) => {
  console.error(error);
  process.exit(1);
});
