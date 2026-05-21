import { createServer } from 'node:http';
import { createApp } from './app';
import { connectPrisma, disconnectPrisma } from './prisma/client';
import { setupRealtime } from './socket';

async function bootstrap() {
  await connectPrisma();

  const app = createApp();
  const server = createServer(app);
  setupRealtime(server);

  const port = Number(process.env.PORT ?? 3000);
  server.listen(port, () => {
    console.log(`Retail Lens API listening on port ${port}`);
  });

  const shutdown = async () => {
    server.close(async () => {
      await disconnectPrisma();
      process.exit(0);
    });
  };

  process.on('SIGINT', shutdown);
  process.on('SIGTERM', shutdown);
}

void bootstrap();
import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { Logger } from 'nestjs-pino';
import { AppModule } from './app.module';
import { HttpExceptionFilter } from './common/filters/http-exception.filter';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.useLogger(app.get(Logger));
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: true,
    }),
  );
  app.useGlobalFilters(new HttpExceptionFilter());
  app.setGlobalPrefix('api/v1');

  const config = new DocumentBuilder()
    .setTitle('Retail Lens API')
    .setDescription('Backend APIs for optical retail operations')
    .setVersion('1.0.0')
    .addBearerAuth()
    .build();
  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document);

  await app.listen(process.env.PORT ?? 3000);
}
bootstrap();
