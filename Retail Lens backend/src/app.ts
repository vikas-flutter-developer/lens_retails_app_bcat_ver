import express from 'express';
import pinoHttp from 'pino-http';
import swaggerUi from 'swagger-ui-express';
import { openApiDocument } from './config/swagger';
import { errorHandler } from './middleware/error-handler';
import { notFoundHandler } from './middleware/not-found';
import { requestIdMiddleware } from './middleware/request-id';
import { apiV1Router } from './routes';
import cors from 'cors';

export function createApp() {
  const app = express();

  app.use(pinoHttp({ level: process.env.LOG_LEVEL ?? 'info' }));
  app.use(express.json({ limit: '50mb' }));
  app.use(express.urlencoded({ limit: '50mb', extended: true }));
  app.use(requestIdMiddleware);
  app.use(cors());

  // Automatically trim and sanitize trailing spaces, newlines (%0A), tabs, or double /v1/v1/ from incoming URLs
  app.use((req, res, next) => {
    try {
      let decodedUrl = decodeURIComponent(req.url);
      let trimmed = decodedUrl.trim();
      
      // Auto-correct accidental double /v1/v1/ or /api/v1/v1/ paths
      if (trimmed.includes('/v1/v1/')) {
        trimmed = trimmed.replace('/v1/v1/', '/v1/');
      }
      
      if (trimmed !== req.url) {
        req.url = trimmed;
      }
    } catch (e) {
      // Safe fallback
    }
    next();
  });

  app.get('/', (req, res) => {
    res.json({
      status: 'ok',
      service: 'retail-lens-api',
      timestamp: new Date().toISOString()
    });
  });

  app.use('/api/docs', swaggerUi.serve, swaggerUi.setup(openApiDocument));
  app.use('/api/v1', apiV1Router);

  app.use(notFoundHandler);
  app.use(errorHandler);

  return app;
}
