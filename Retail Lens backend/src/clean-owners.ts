import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('Starting deletion of John Doe (user@example.com)...');
  
  const targetEmail = 'user@example.com';
  const owner = await prisma.user.findUnique({
    where: { email: targetEmail }
  });

  if (!owner) {
    console.log(`User ${targetEmail} not found.`);
    return;
  }

  console.log(`Deleting owner: ${owner.email}...`);
  
  // Delete linked employee profile first to prevent foreign key errors
  await prisma.employee.deleteMany({
    where: { userId: owner.id }
  });

  // Delete linked refresh tokens
  await prisma.refreshToken.deleteMany({
    where: { userId: owner.id }
  });

  // Delete the user
  await prisma.user.delete({
    where: { id: owner.id }
  });

  console.log('John Doe (user@example.com) deleted successfully!');
}

main()
  .catch((e) => {
    console.error('Error deleting user:', e);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
