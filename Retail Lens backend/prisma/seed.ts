import { PrismaClient, UserRole } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  const passwordHash = await bcrypt.hash('ChangeMe123!', 10);

  await prisma.user.upsert({
    where: { email: 'owner@retaillens.local' },
    update: {},
    create: {
      email: 'owner@retaillens.local',
      fullName: 'Store Owner',
      passwordHash,
      role: UserRole.OWNER,
    },
  });

  await prisma.storeSettings.upsert({
    where: { id: 'default-store-settings' },
    update: {
      storeName: 'Retail Lens',
    },
    create: {
      id: 'default-store-settings',
      storeName: 'Retail Lens',
    },
  });
}

main()
  .then(async () => {
    await prisma.$disconnect();
  })
  .catch(async (error) => {
    console.error(error);
    await prisma.$disconnect();
    process.exit(1);
  });
