const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const jobs = await prisma.jobCard.findMany({
    take: 5,
    select: { id: true, billNo: true, status: true },
    orderBy: { createdAt: 'desc' }
  });
  console.log('🔍 RECENT JOB CARDS:');
  console.log(JSON.stringify(jobs, null, 2));
}

main()
  .catch(e => console.error(e))
  .finally(async () => await prisma.$disconnect());
