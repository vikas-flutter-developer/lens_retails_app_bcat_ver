import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('--- Job Cards / Orders ---');
  const orders = await prisma.jobCard.findMany({
    include: {
      customer: true,
      items: true,
    },
  });
  
  console.log(`Total orders found: ${orders.length}`);
  orders.forEach(o => {
    console.log(`ID: ${o.id}, BillNo: ${o.billNo}, Customer: ${o.customer.fullName}, Status: ${o.status}`);
  });
}

main()
  .catch(e => console.error(e))
  .finally(async () => await prisma.$disconnect());
