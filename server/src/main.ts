import type { ServerResponse } from 'node:http';
import { HttpAdapterHost, NestFactory } from '@nestjs/core';
import {
  FastifyAdapter,
  type NestFastifyApplication,
} from '@nestjs/platform-fastify';
import type { FastifyRequest } from 'fastify';
import { AppModule } from './app.module';
import { PrismaExceptionFilter } from './common/prisma-exception.filter';
import { apiReference } from '@config/docs.config';

async function bootstrap() {
  const app = await NestFactory.create<NestFastifyApplication>(
    AppModule,
    new FastifyAdapter(),
  );

  app.useGlobalFilters(
    new PrismaExceptionFilter(app.get(HttpAdapterHost).httpAdapter),
  );
  app.enableShutdownHooks();
  app.enableCors({ origin: '*' });

  // `apiReference` hands back a raw `(req, res) => void` handler — typed as a
  // union with its Express variant since `withFastify` is just a runtime flag
  // — so it is registered on Fastify's own instance rather than through
  // Nest's `.use()`, and `reply.hijack()` stops Fastify from also trying to
  // send a response.
  const scalarHandler = apiReference(app) as (
    req: FastifyRequest,
    res: ServerResponse,
  ) => void;
  app
    .getHttpAdapter()
    .getInstance()
    .get('/api', (request, reply) => {
      reply.hijack();
      scalarHandler(request, reply.raw);
    });

  await app.listen(Bun.env.PORT ?? 3000, '0.0.0.0');
}

bootstrap().catch((error) => {
  console.error(error);
  process.exit(1);
});
