"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.VendorsService = void 0;
const client_1 = require("../prisma/client");
class VendorsService {
    static async getAllVendors() {
        return await client_1.prisma.vendor.findMany({
            orderBy: {
                name: 'asc',
            },
        });
    }
    static async createOrUpdateVendor(data) {
        const { accountId, ...rest } = data;
        return await client_1.prisma.vendor.upsert({
            where: { accountId },
            update: rest,
            create: { accountId, ...rest },
        });
    }
    static async deleteVendor(id) {
        return await client_1.prisma.vendor.delete({
            where: { id },
        });
    }
}
exports.VendorsService = VendorsService;
//# sourceMappingURL=vendors.service.js.map