import { INestApplication } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { apiReference as reference } from '@scalar/nestjs-api-reference';

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

export const apiReference = (app: INestApplication<any>) =>
  reference({
    content: () => SwaggerModule.createDocument(app, config),
    theme: 'kepler',
  });
