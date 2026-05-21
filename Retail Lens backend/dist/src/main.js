"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const node_http_1 = require("node:http");
const app_1 = require("./app");
const client_1 = require("./prisma/client");
const socket_1 = require("./socket");
async function bootstrap() {
    await (0, client_1.connectPrisma)();
    const app = (0, app_1.createApp)();
    const server = (0, node_http_1.createServer)(app);
    (0, socket_1.setupRealtime)(server);
    const port = Number(process.env.PORT ?? 3000);
    server.listen(port, () => {
        console.log(`Retail Lens API listening on port ${port}`);
    });
    const shutdown = async () => {
        server.close(async () => {
            await (0, client_1.disconnectPrisma)();
            process.exit(0);
        });
    };
    process.on('SIGINT', shutdown);
    process.on('SIGTERM', shutdown);
}
void bootstrap();
//# sourceMappingURL=main.js.map