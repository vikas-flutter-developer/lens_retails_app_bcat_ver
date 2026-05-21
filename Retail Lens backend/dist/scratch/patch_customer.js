"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const client_1 = require("@prisma/client");
const prisma = new client_1.PrismaClient();
async function main() {
    const customer = await prisma.customer.update({
        where: { phone: '9876543211' },
        data: {
            dob: '15-08-1992',
            address: '123 Retail Park, Mumbai'
        }
    });
    console.log('SUCCESSFULLY PATCHED CUSTOMER:', customer);
}
main()
    .catch(e => console.error('FAILED TO PATCH:', e))
    .finally(async () => {
    await prisma.$disconnect();
});
//# sourceMappingURL=patch_customer.js.map