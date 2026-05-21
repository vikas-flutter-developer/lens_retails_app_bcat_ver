import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  const jobCards = await prisma.jobCard.findMany({
    take: 5,
    orderBy: { createdAt: 'desc' },
    include: { customer: true }
  });

  console.log('\n--- ACTIVE JOBCARD / ORDER IDs ---');
  if (jobCards.length === 0) {
    console.log('No Job Cards found in the database. Please save an order first!');
  } else {
    jobCards.forEach((jc) => {
      console.log(`ID: ${jc.id} | Bill: ${jc.billNo} | Customer: ${jc.customer?.fullName}`);
    });
  }
  console.log('---------------------------------\n');
}

main().catch(console.error).finally(() => prisma.$disconnect());
