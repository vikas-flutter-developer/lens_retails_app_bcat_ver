import { prisma } from './prisma/client';
import { JobCardStatus } from '@prisma/client';

async function main() {
  console.log('🌱 Seeding historical purchase data for Amit Kumar (9988776655)...');

  // 1. Upsert Customer "Amit Kumar"
  const customer = await prisma.customer.upsert({
    where: { phone: '9988776655' },
    update: {
      fullName: 'Amit Kumar',
      address: 'B-45, Sector 62, Noida',
    },
    create: {
      fullName: 'Amit Kumar',
      phone: '9988776655',
      address: 'B-45, Sector 62, Noida',
    },
  });
  console.log(`✅ Resolved Customer: ${customer.fullName} (ID: ${customer.id})`);

  // 2. Clear old job cards for Amit Kumar to prevent duplicate mock data piling up
  const deletedItems = await prisma.jobCardItem.deleteMany({
    where: { jobCard: { customerId: customer.id } },
  });
  const deletedPayments = await prisma.payment.deleteMany({
    where: { jobCard: { customerId: customer.id } },
  });
  const deletedCards = await prisma.jobCard.deleteMany({
    where: { customerId: customer.id },
  });
  console.log(`🗑️ Cleared ${deletedCards.count} old test job cards for a clean seed.`);

  // 3. Create Order 1: Frame purchase of ₹1,000 (2 months ago)
  const dateTwoMonthsAgo = new Date();
  dateTwoMonthsAgo.setMonth(dateTwoMonthsAgo.getMonth() - 2);

  const order1 = await prisma.jobCard.create({
    data: {
      customerId: customer.id,
      status: JobCardStatus.DELIVERED,
      totalAmount: 1000.0,
      paidAmount: 1000.0,
      dueAmount: 0.0,
      billNo: 'JC-1002',
      billSeries: 'ORD_25-26',
      orderType: 'RX',
      bookedBy: 'Owner',
      godown: 'Main Branch',
      createdAt: dateTwoMonthsAgo,
      items: {
        create: [
          {
            description: 'Retro Black Round Frame',
            quantity: 1,
            unitPrice: 1000.0,
            lineTotal: 1000.0,
            eye: 'Both',
          },
        ],
      },
      payments: {
        create: [
          {
            amount: 1000.0,
            paymentType: 'CASH',
            createdAt: dateTwoMonthsAgo,
          },
        ],
      },
    },
  });
  console.log(`🎉 Seeded Order 1: ${order1.billNo} - Frame purchase of ₹1,000 (Delivered)`);

  // 4. Create Order 2: Lens purchase of ₹1,500 (1 month ago)
  const dateOneMonthAgo = new Date();
  dateOneMonthAgo.setMonth(dateOneMonthAgo.getMonth() - 1);

  const order2 = await prisma.jobCard.create({
    data: {
      customerId: customer.id,
      status: JobCardStatus.DELIVERED,
      totalAmount: 1500.0,
      paidAmount: 1500.0,
      dueAmount: 0.0,
      billNo: 'JC-1009',
      billSeries: 'ORD_25-26',
      orderType: 'RX',
      bookedBy: 'Owner',
      godown: 'Main Branch',
      createdAt: dateOneMonthAgo,
      items: {
        create: [
          {
            description: 'Anti-Reflective Single Vision Lenses',
            quantity: 1,
            unitPrice: 1500.0,
            lineTotal: 1500.0,
            eye: 'Both',
          },
        ],
      },
      payments: {
        create: [
          {
            amount: 1500.0,
            paymentType: 'UPI',
            createdAt: dateOneMonthAgo,
          },
        ],
      },
    },
  });
  console.log(`🎉 Seeded Order 2: ${order2.billNo} - Lens purchase of ₹1,500 (Delivered)`);

  console.log('🌟 Seeding Completed successfully! Customer history metrics are fully armed in PostgreSQL.');
}

main()
  .catch((e) => {
    console.error('❌ Seeding failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
