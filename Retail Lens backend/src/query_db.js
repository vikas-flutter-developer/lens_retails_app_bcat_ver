const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const cards = await prisma.jobCard.findMany({
    select: {
      id: true,
      customerId: true,
      billNo: true,
    }
  });
  console.log('--- ACTIVE JOB CARDS IN DATABASE ---');
  console.log(JSON.stringify(cards, null, 2));
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
