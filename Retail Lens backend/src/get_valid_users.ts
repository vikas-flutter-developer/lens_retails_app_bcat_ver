import { prisma } from './prisma/client';

async function main() {
  console.log('🔍 Fetching registered users from your database...');

  const users = await prisma.user.findMany({
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
  .finally(() => prisma.$disconnect());
