import { PrismaClient, TaskStatus, Priority } from '@prisma/client';

const prisma = new PrismaClient();

const staffNames = [
  { name: 'Rohan Sharma', role: 'Sales Executive', phone: '9876543221' },
  { name: 'Ananya Iyer', role: 'Optometrist', phone: '9876543222' },
  { name: 'Vikram Singh', role: 'Technician', phone: '9876543223' },
  { name: 'Sneha Patel', role: 'Store Manager', phone: '9876543224' },
  { name: 'Kunal Sen', role: 'Billing Executive', phone: '9876543225' }
];

async function main() {
  console.log('🌱 Seeding 5 staff members and tasks...');

  for (const staff of staffNames) {
    // 1. Create employee
    const employee = await prisma.employee.create({
      data: {
        name: staff.name,
        role: staff.role,
        phone: staff.phone,
        status: 'Active'
      }
    });
    console.log(`👤 Created Employee: ${employee.name} (ID: ${employee.id})`);

    // 2. Create 2 COMPLETED tasks
    for (let i = 1; i <= 2; i++) {
      await prisma.task.create({
        data: {
          title: `Completed Task ${i} for ${employee.name}`,
          description: `This is completed task ${i}`,
          status: TaskStatus.COMPLETED,
          priority: Priority.MEDIUM,
          assignedToId: employee.id,
          dueDate: 'Today'
        }
      });
    }

    // 3. Create 8 PENDING tasks
    for (let i = 1; i <= 8; i++) {
      await prisma.task.create({
        data: {
          title: `Pending Task ${i} for ${employee.name}`,
          description: `This is pending task ${i}`,
          status: TaskStatus.PENDING,
          priority: Priority.MEDIUM,
          assignedToId: employee.id,
          dueDate: 'Today'
        }
      });
    }
    console.log(`✅ Created 10 tasks (2 Completed, 8 Pending) for ${employee.name}`);
  }

  console.log('🎉 Seeding completed successfully!');
}

main()
  .catch((e) => console.error('❌ Seeding failed:', e))
  .finally(async () => await prisma.$disconnect());
