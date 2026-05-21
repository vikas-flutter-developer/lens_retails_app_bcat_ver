"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const client_1 = require("@prisma/client");
const prisma = new client_1.PrismaClient();
async function main() {
    console.log('🗑️ Cleaning existing job cards and items...');
    await prisma.payment.deleteMany({});
    await prisma.jobCardItem.deleteMany({});
    await prisma.jobCard.deleteMany({});
    await prisma.customer.deleteMany({});
    console.log('🌱 Seeding 6 real customers (5 active, 1 delivered) with beautiful itemized orders...');
    const customer1 = await prisma.customer.create({
        data: {
            fullName: 'Rohan Mehta',
            phone: '9876543210',
            email: 'rohan.mehta@gmail.com',
        },
    });
    const jobCard1 = await prisma.jobCard.create({
        data: {
            id: 'job_rohan_1',
            customerId: customer1.id,
            status: client_1.JobCardStatus.DELIVERED,
            totalAmount: 3500.00,
            paidAmount: 3500.00,
            dueAmount: 0.00,
            billNo: 'INV-2026-001',
            billSeries: 'ORD_25-26',
            orderType: 'RX',
            bookedBy: 'Ananya Iyer',
            godown: 'Main Branch',
            title: 'Premium Blue Cut Glasses',
            priority: 'High',
            notes: 'Customer requested soft silicon nose pads.',
            createdAt: new Date('2026-05-09T10:00:00Z'),
            items: {
                create: [
                    {
                        productId: 'lens_crizal_prevencia',
                        description: 'Crizal Prevencia Anti-Glare Blue Cut Lens',
                        quantity: 1,
                        unitPrice: 1500.00,
                        lineTotal: 1500.00,
                        sph: '-1.50',
                        cyl: '-0.50',
                        axis: '90',
                        add: '+1.50',
                        eye: 'R',
                    },
                    {
                        productId: 'lens_crizal_prevencia',
                        description: 'Crizal Prevencia Anti-Glare Blue Cut Lens',
                        quantity: 1,
                        unitPrice: 1500.00,
                        lineTotal: 1500.00,
                        sph: '-1.25',
                        cyl: '-0.75',
                        axis: '180',
                        add: '+1.50',
                        eye: 'L',
                    },
                    {
                        productId: 'frame_rayban_aviator',
                        description: 'Ray-Ban Aviator Golden Frame',
                        quantity: 1,
                        unitPrice: 500.00,
                        lineTotal: 500.00,
                        eye: 'Both',
                    },
                ],
            },
        },
    });
    await prisma.payment.create({
        data: {
            jobCardId: jobCard1.id,
            amount: 3500.00,
            paymentType: 'UPI',
        },
    });
    const customer2 = await prisma.customer.create({
        data: {
            fullName: 'Amit Patel',
            phone: '9876543211',
            email: 'amit.patel@gmail.com',
        },
    });
    const jobCard2 = await prisma.jobCard.create({
        data: {
            id: 'job_amit_2',
            customerId: customer2.id,
            status: client_1.JobCardStatus.READY,
            totalAmount: 1800.00,
            paidAmount: 1000.00,
            dueAmount: 800.00,
            billNo: 'INV-2026-003',
            billSeries: 'ORD_25-26',
            orderType: 'Single Finish',
            bookedBy: 'Rohan Sharma',
            godown: 'Main Branch',
            title: 'Daily Wear Anti-Reflective Glasses',
            priority: 'Medium',
            notes: 'Ensure proper lens fitting.',
            createdAt: new Date('2026-05-09T11:30:00Z'),
            items: {
                create: [
                    {
                        productId: 'lens_essilor_trio',
                        description: 'Essilor Trio Clean Anti-Reflective Lens',
                        quantity: 1,
                        unitPrice: 600.00,
                        lineTotal: 600.00,
                        sph: '-2.00',
                        cyl: '0.00',
                        axis: '0',
                        add: '0.00',
                        eye: 'R',
                    },
                    {
                        productId: 'lens_essilor_trio',
                        description: 'Essilor Trio Clean Anti-Reflective Lens',
                        quantity: 1,
                        unitPrice: 600.00,
                        lineTotal: 600.00,
                        sph: '-2.00',
                        cyl: '0.00',
                        axis: '0',
                        add: '0.00',
                        eye: 'L',
                    },
                    {
                        productId: 'frame_oakley_pitchman',
                        description: 'Oakley Pitchman R Satin Black Frame',
                        quantity: 1,
                        unitPrice: 600.00,
                        lineTotal: 600.00,
                        eye: 'Both',
                    },
                ],
            },
        },
    });
    await prisma.payment.create({
        data: {
            jobCardId: jobCard2.id,
            amount: 1000.00,
            paymentType: 'CASH',
        },
    });
    const customer3 = await prisma.customer.create({
        data: {
            fullName: 'Pooja Sen',
            phone: '9876543212',
            email: 'pooja.sen@gmail.com',
        },
    });
    const jobCard3 = await prisma.jobCard.create({
        data: {
            id: 'job_pooja_3',
            customerId: customer3.id,
            status: client_1.JobCardStatus.IN_PROGRESS,
            totalAmount: 6500.00,
            paidAmount: 3000.00,
            dueAmount: 3500.00,
            billNo: 'INV-2026-002',
            billSeries: 'ORD_25-26',
            orderType: 'RX',
            bookedBy: 'Ananya Iyer',
            godown: 'Main Branch',
            title: 'Zeiss Premium Progressive Glasses',
            priority: 'High',
            notes: 'Urgent delivery requested.',
            createdAt: new Date('2026-05-09T13:15:00Z'),
            items: {
                create: [
                    {
                        productId: 'lens_zeiss_duravision',
                        description: 'Zeiss DuraVision Platinum Blue Guard Lens',
                        quantity: 1,
                        unitPrice: 2500.00,
                        lineTotal: 2500.00,
                        sph: '-3.50',
                        cyl: '-1.00',
                        axis: '95',
                        add: '+2.00',
                        eye: 'R',
                    },
                    {
                        productId: 'lens_zeiss_duravision',
                        description: 'Zeiss DuraVision Platinum Blue Guard Lens',
                        quantity: 1,
                        unitPrice: 2500.00,
                        lineTotal: 2500.00,
                        sph: '-3.25',
                        cyl: '-1.25',
                        axis: '85',
                        add: '+2.00',
                        eye: 'L',
                    },
                    {
                        productId: 'frame_vogue_cat_eye',
                        description: 'Vogue Matte Blue Cat-Eye Frame',
                        quantity: 1,
                        unitPrice: 1500.00,
                        lineTotal: 1500.00,
                        eye: 'Both',
                    },
                ],
            },
        },
    });
    await prisma.payment.create({
        data: {
            jobCardId: jobCard3.id,
            amount: 3000.00,
            paymentType: 'CARD',
        },
    });
    const customer4 = await prisma.customer.create({
        data: {
            fullName: 'Sneha Gupta',
            phone: '9876543213',
            email: 'sneha.gupta@gmail.com',
        },
    });
    const jobCard4 = await prisma.jobCard.create({
        data: {
            id: 'job_sneha_4',
            customerId: customer4.id,
            status: client_1.JobCardStatus.DRAFT,
            totalAmount: 4200.00,
            paidAmount: 2000.00,
            dueAmount: 2200.00,
            billNo: 'INV-2026-004',
            billSeries: 'ORD_25-26',
            orderType: 'RX',
            bookedBy: 'Ananya Iyer',
            godown: 'Main Branch',
            title: 'Hoya Blue Cut Computer Glasses',
            priority: 'Low',
            notes: 'Needs hydrophobic coating.',
            createdAt: new Date('2026-05-09T14:10:00Z'),
            items: {
                create: [
                    {
                        productId: 'lens_hoya_hilux',
                        description: 'Hoya Hilux Blue Control Lens',
                        quantity: 1,
                        unitPrice: 1600.00,
                        lineTotal: 1600.00,
                        sph: '-0.75',
                        cyl: '-0.50',
                        axis: '45',
                        add: '0.00',
                        eye: 'R',
                    },
                    {
                        productId: 'lens_hoya_hilux',
                        description: 'Hoya Hilux Blue Control Lens',
                        quantity: 1,
                        unitPrice: 1600.00,
                        lineTotal: 1600.00,
                        sph: '-0.50',
                        cyl: '-0.25',
                        axis: '30',
                        add: '0.00',
                        eye: 'L',
                    },
                    {
                        productId: 'frame_fastrack_sporty',
                        description: 'Fastrack Sporty Rectangular Frame',
                        quantity: 1,
                        unitPrice: 1000.00,
                        lineTotal: 1000.00,
                        eye: 'Both',
                    },
                ],
            },
        },
    });
    await prisma.payment.create({
        data: {
            jobCardId: jobCard4.id,
            amount: 2000.00,
            paymentType: 'UPI',
        },
    });
    const customer5 = await prisma.customer.create({
        data: {
            fullName: 'Vikram Malhotra',
            phone: '9876543214',
            email: 'vikram.malhotra@gmail.com',
        },
    });
    const jobCard5 = await prisma.jobCard.create({
        data: {
            id: 'job_vikram_5',
            customerId: customer5.id,
            status: client_1.JobCardStatus.IN_PROGRESS,
            totalAmount: 12500.00,
            paidAmount: 6000.00,
            dueAmount: 6500.00,
            billNo: 'INV-2026-005',
            billSeries: 'ORD_25-26',
            orderType: 'RX',
            bookedBy: 'Ananya Iyer',
            godown: 'Main Branch',
            title: 'Varilux Progressive Luxury Spectacles',
            priority: 'High',
            notes: 'Laser engraving requested by client.',
            createdAt: new Date('2026-05-09T14:25:00Z'),
            items: {
                create: [
                    {
                        productId: 'lens_varilux_comfort',
                        description: 'Essilor Varilux Comfort Max Lens',
                        quantity: 1,
                        unitPrice: 4500.00,
                        lineTotal: 4500.00,
                        sph: '-4.25',
                        cyl: '-1.50',
                        axis: '115',
                        add: '+2.50',
                        eye: 'R',
                    },
                    {
                        productId: 'lens_varilux_comfort',
                        description: 'Essilor Varilux Comfort Max Lens',
                        quantity: 1,
                        unitPrice: 4500.00,
                        lineTotal: 4500.00,
                        sph: '-4.00',
                        cyl: '-1.75',
                        axis: '120',
                        add: '+2.50',
                        eye: 'L',
                    },
                    {
                        productId: 'frame_police_titanium',
                        description: 'Police Titanium Premium Rimless Frame',
                        quantity: 1,
                        unitPrice: 3500.00,
                        lineTotal: 3500.00,
                        eye: 'Both',
                    },
                ],
            },
        },
    });
    await prisma.payment.create({
        data: {
            jobCardId: jobCard5.id,
            amount: 6000.00,
            paymentType: 'CARD',
        },
    });
    const customer6 = await prisma.customer.create({
        data: {
            fullName: 'Kiran Rao',
            phone: '9876543215',
            email: 'kiran.rao@gmail.com',
        },
    });
    const jobCard6 = await prisma.jobCard.create({
        data: {
            id: 'job_kiran_6',
            customerId: customer6.id,
            status: client_1.JobCardStatus.READY,
            totalAmount: 2900.00,
            paidAmount: 2000.00,
            dueAmount: 900.00,
            billNo: 'INV-2026-006',
            billSeries: 'ORD_25-26',
            orderType: 'Single Finish',
            bookedBy: 'Rohan Sharma',
            godown: 'Main Branch',
            title: 'Bausch & Lomb Contact Lens Deal',
            priority: 'Medium',
            notes: 'Include 1 complimentary contact lens solution.',
            createdAt: new Date('2026-05-09T14:40:00Z'),
            items: {
                create: [
                    {
                        productId: 'lens_bausch_lomb',
                        description: 'Bausch & Lomb PureVision 2 HD Contact Lens',
                        quantity: 1,
                        unitPrice: 1200.00,
                        lineTotal: 1200.00,
                        sph: '-2.50',
                        cyl: '0.00',
                        axis: '0',
                        add: '0.00',
                        eye: 'R',
                    },
                    {
                        productId: 'lens_bausch_lomb',
                        description: 'Bausch & Lomb PureVision 2 HD Contact Lens',
                        quantity: 1,
                        unitPrice: 1200.00,
                        lineTotal: 1200.00,
                        sph: '-2.25',
                        cyl: '0.00',
                        axis: '0',
                        add: '0.00',
                        eye: 'L',
                    },
                    {
                        productId: 'solution_renu_fresh',
                        description: 'Renu Fresh Contact Lens Solution 355ml',
                        quantity: 1,
                        unitPrice: 500.00,
                        lineTotal: 500.00,
                        eye: 'Both',
                    },
                ],
            },
        },
    });
    await prisma.payment.create({
        data: {
            jobCardId: jobCard6.id,
            amount: 2000.00,
            paymentType: 'CASH',
        },
    });
    console.log('🎉 Seeding successfully completed!');
}
main()
    .catch((e) => console.error('❌ Seeding failed:', e))
    .finally(async () => await prisma.$disconnect());
//# sourceMappingURL=seed_real_items.js.map