import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  const customer = await prisma.customer.update({
    where: { phone: '9876543211' }, // Amit Patel's phone number from diagnostics
    data: {
      dob: '15-08-1992',
      address: '123 Retail Park, Mumbai'
    }
  });
  console.log('SUCCESSFULLY PATCHED CUSTOMER:', customer);
}

main()
  .catch(e => console.error('FAILED TO PATCH:', e))
  .finally(async () => {
    await prisma.$disconnect();
  });
