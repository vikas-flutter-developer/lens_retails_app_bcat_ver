import { Server } from 'socket.io';
export declare class RealtimeGateway {
    server: Server;
    handleMessage(payload: Record<string, unknown>): {
        ok: boolean;
    };
}
