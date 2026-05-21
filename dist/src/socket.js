"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.setupRealtime = setupRealtime;
const socket_io_1 = require("socket.io");
function setupRealtime(server) {
    const io = new socket_io_1.Server(server, {
        cors: { origin: '*' },
        path: '/api/v1/realtime',
    });
    io.on('connection', (socket) => {
        socket.on('state-change', (payload) => {
            io.emit('state-change', payload);
        });
    });
    return io;
}
//# sourceMappingURL=socket.js.map