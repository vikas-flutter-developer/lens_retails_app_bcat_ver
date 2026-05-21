"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const client_1 = require("./prisma/client");
async function main() {
    console.log('🔍 Fetching registered users from your database...');
    const users = await client_1.prisma.user.findMany({
        select: {
            id: true,
            email: true,
            role: true,
            fullName: true
        }
    });
    console.log('📋 Valid Users in your database:');
    console.log(JSON.stringify(users, null, 2));
}
main()
    .catch((e) => console.error('❌ Error fetching users:', e))
    .finally(() => client_1.prisma.$disconnect());
//# sourceMappingURL=get_valid_users.js.map