import express from 'express';
import pinoHttp from 'pino-http';
import swaggerUi from 'swagger-ui-express';
import { openApiDocument } from './config/swagger';
import { errorHandler } from './middleware/error-handler';
import { notFoundHandler } from './middleware/not-found';
import { requestIdMiddleware } from './middleware/request-id';
import { apiV1Router } from './routes';

export function createApp() {
  const app = express();

  app.use(pinoHttp({ level: process.env.LOG_LEVEL ?? 'info' }));
  app.use(express.json());
  app.use(requestIdMiddleware);

  app.use('/api/docs', swaggerUi.serve, swaggerUi.setup(openApiDocument));
  app.use('/api/v1', apiV1Router);

  app.use(notFoundHandler);
  app.use(errorHandler);

  return app;
}
