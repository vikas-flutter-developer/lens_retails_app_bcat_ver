"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.prisma = void 0;
exports.connectPrisma = connectPrisma;
exports.disconnectPrisma = disconnectPrisma;
const client_1 = require("@prisma/client");
exports.prisma = new client_1.PrismaClient();
async function connectPrisma() {
    if (process.env.SKIP_DB_CONNECT === 'true') {
        return;
    }
    await exports.prisma.$connect();
}
async function disconnectPrisma() {
    await exports.prisma.$disconnect();
}
//# sourceMappingURL=client.js.map