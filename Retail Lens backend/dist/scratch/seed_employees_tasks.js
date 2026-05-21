"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const client_1 = require("@prisma/client");
const prisma = new client_1.PrismaClient();
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
        const employee = await prisma.employee.create({
            data: {
                name: staff.name,
                role: staff.role,
                phone: staff.phone,
                status: 'Active'
            }
        });
        console.log(`👤 Created Employee: ${employee.name} (ID: ${employee.id})`);
        for (let i = 1; i <= 2; i++) {
            await prisma.task.create({
                data: {
                    title: `Completed Task ${i} for ${employee.name}`,
                    description: `This is completed task ${i}`,
                    status: client_1.TaskStatus.COMPLETED,
                    priority: client_1.Priority.MEDIUM,
                    assignedToId: employee.id,
                    dueDate: 'Today'
                }
            });
        }
        for (let i = 1; i <= 8; i++) {
            await prisma.task.create({
                data: {
                    title: `Pending Task ${i} for ${employee.name}`,
                    description: `This is pending task ${i}`,
                    status: client_1.TaskStatus.PENDING,
                    priority: client_1.Priority.MEDIUM,
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
//# sourceMappingURL=seed_employees_tasks.js.map