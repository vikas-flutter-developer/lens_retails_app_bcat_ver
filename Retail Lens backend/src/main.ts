// Trigger reload
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
