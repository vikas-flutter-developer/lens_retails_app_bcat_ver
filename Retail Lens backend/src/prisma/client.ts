import { PrismaClient } from '@prisma/client';

export const prisma = new PrismaClient();

export async function connectPrisma() {
  if (process.env.SKIP_DB_CONNECT === 'true') {
    return;
  }

  await prisma.$connect();
}

export async function disconnectPrisma() {
  await prisma.$disconnect();
}
