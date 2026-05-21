"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const client_1 = require("@prisma/client");
const prisma = new client_1.PrismaClient();
async function main() {
    console.log('Starting deletion of John Doe (user@example.com)...');
    const targetEmail = 'user@example.com';
    const owner = await prisma.user.findUnique({
        where: { email: targetEmail }
    });
    if (!owner) {
        console.log(`User ${targetEmail} not found.`);
        return;
    }
    console.log(`Deleting owner: ${owner.email}...`);
    await prisma.employee.deleteMany({
        where: { userId: owner.id }
    });
    await prisma.refreshToken.deleteMany({
        where: { userId: owner.id }
    });
    await prisma.user.delete({
        where: { id: owner.id }
    });
    console.log('John Doe (user@example.com) deleted successfully!');
}
main()
    .catch((e) => {
    console.error('Error deleting user:', e);
})
    .finally(async () => {
    await prisma.$disconnect();
});
//# sourceMappingURL=clean-owners.js.map