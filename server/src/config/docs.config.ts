import { INestApplication } from '@nestjs/common';
import type { ServerResponse } from 'node:http';
import type { FastifyRequest } from 'fastify';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { apiReference as reference } from '@scalar/nestjs-api-reference';

type FastifyHandler = (req: FastifyRequest, res: ServerResponse) => void;

const config = new DocumentBuilder()
  .setTitle('IT Support Documentation')
  .setDescription('The IT Support API Documentation')
  .setVersion('0.1.0')
  .addTag('Support')
  .addBearerAuth(
    { type: 'http', scheme: 'bearer', bearerFormat: 'JWT' },
    'bearer',
  )
  .addSecurityRequirements('bearer')
  .build();

export function apiReference(app: INestApplication<any>) {
  return reference({
    content: () => SwaggerModule.createDocument(app, config),
    theme: 'saturn',
    withFastify: true,
  }) as FastifyHandler;
}
