import { Server as HttpServer } from 'node:http';
import { Server } from 'socket.io';

export function setupRealtime(server: HttpServer) {
  const io = new Server(server, {
    cors: { origin: '*' },
    path: '/api/v1/realtime',
  });

  io.on('connection', (socket) => {
    socket.on('state-change', (payload: Record<string, unknown>) => {
      io.emit('state-change', payload);
    });
  });

  return io;
}
