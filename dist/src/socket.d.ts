import { Server as HttpServer } from 'node:http';
import { Server } from 'socket.io';
export declare function setupRealtime(server: HttpServer): Server<import("socket.io").DefaultEventsMap, import("socket.io").DefaultEventsMap, import("socket.io").DefaultEventsMap, any>;
