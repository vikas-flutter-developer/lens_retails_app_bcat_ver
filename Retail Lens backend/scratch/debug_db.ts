import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('--- Employees ---');
  const employees = await prisma.employee.findMany();
  employees.forEach(emp => {
    console.log(`ID: ${emp.id}, Name: ${emp.name}`);
  });

  console.log('\n--- Customers ---');
  const customers = await prisma.customer.findMany();
  customers.forEach(cust => {
    console.log(`ID: ${cust.id}, Name: ${cust.fullName}, Phone: ${cust.phone}`);
  });
}

main()
  .catch(e => console.error(e))
  .finally(async () => await prisma.$disconnect());
