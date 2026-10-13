import { HttpAdapterHost, NestFactory } from '@nestjs/core';
import {
  FastifyAdapter,
  type NestFastifyApplication,
} from '@nestjs/platform-fastify';
import { AppModule } from './app.module';
import { PrismaExceptionFilter } from './common/prisma-exception.filter';
import { apiReference } from '@config/docs.config';
import { env } from '@config/env.config';
import { safeTry, isError } from './common/utils/exception.util'

const app = await safeTry(NestFactory.create<NestFastifyApplication>(
  AppModule,
  new FastifyAdapter(),
  {
    snapshot: true
  }
));

if (isError(app)) {
  console.error("Unable to factorizing the application", app.message);
  process.exit(1);
}

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

const server = await safeTry(app.listen(env.PORT, '0.0.0.0'));
if (isError(server)) {
  console.error("Fails to start the applicaion", server.message)
  process.exit(1);
}

