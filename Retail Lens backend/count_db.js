const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log('--- CREATING FULLY POPULATED CUSTOMER & JOB CARD ---');

  // 1. Create fully populated customer
  const customerId = 'cust_vikas';
  const customer = await prisma.customer.upsert({
    where: { id: customerId },
    update: {
      fullName: 'Vikas Sharma',
      phone: '+919876543211',
      email: 'vikas.sharma@gmail.com'
    },
    create: {
      id: customerId,
      fullName: 'Vikas Sharma',
      phone: '+919876543211',
      email: 'vikas.sharma@gmail.com'
    }
  });
  console.log(`✓ Customer Created: ${customer.fullName} (ID: ${customer.id})`);

  // 2. Clean up any existing job cards for this user to start fresh
  const existingJobCards = await prisma.jobCard.findMany({ where: { customerId } });
  const existingIds = existingJobCards.map(jc => jc.id);
  if (existingIds.length > 0) {
    await prisma.payment.deleteMany({ where: { jobCardId: { in: existingIds } } });
    await prisma.jobCardItem.deleteMany({ where: { jobCardId: { in: existingIds } } });
    await prisma.jobCard.deleteMany({ where: { customerId } });
  }

  // 3. Create fully populated Job Card
  const jobCard = await prisma.jobCard.create({
    data: {
      customerId: customer.id,
      title: 'Progressive Blue-Cut Lens Order',
      priority: 'HIGH',
      status: 'READY',
      billNo: 'INV-10022',
      billSeries: '2026-MAY',
      orderType: 'RX',
      bookedBy: 'Staff-John',
      godown: 'Warehouse A',
      notes: 'Handle with extra care',
      expectedCompletionDate: new Date('2026-05-15T12:00:00.000Z'),
      totalAmount: 150.00,
      paidAmount: 50.00,
      dueAmount: 100.00,
      items: {
        create: [
          {
            productId: 'PROD-LENS-001',
            description: 'Anti-Reflective Blue-Cut Left Lens',
            quantity: 1,
            unitPrice: 150.00,
            lineTotal: 150.00,
            sph: '-1.50',
            cyl: '-0.75',
            axis: '180',
            add: '+1.50',
            eye: 'LEFT'
          }
        ]
      },
      payments: {
        create: [
          {
            amount: 50.00,
            paymentType: 'CASH',
            idempotencyKey: 'vikas_pay_ref_101'
          }
        ]
      }
    },
    include: {
      items: true,
      payments: true
    }
  });

  console.log(`✓ Job Card Created: ${jobCard.title} (ID: ${jobCard.id})`);
  console.log('----------------------------------------------------');
}

main()
  .catch(e => console.error(e))
  .finally(async () => {
    await prisma.$disconnect();
  });
