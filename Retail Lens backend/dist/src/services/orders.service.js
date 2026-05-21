"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.OrdersService = void 0;
const client_1 = require("../prisma/client");
const client_2 = require("@prisma/client");
const inventory_sync_util_1 = require("../utils/inventory-sync.util");
function parseJobCardStatus(statusStr) {
    if (!statusStr)
        return client_2.JobCardStatus.DRAFT;
    const s = statusStr.toUpperCase().replace(' ', '_');
    if (s === 'PENDING')
        return client_2.JobCardStatus.DRAFT;
    if (Object.values(client_2.JobCardStatus).includes(s)) {
        return s;
    }
    return client_2.JobCardStatus.DRAFT;
}
class OrdersService {
    static async getAllOrders() {
        const orders = await client_1.prisma.jobCard.findMany({
            include: {
                customer: true,
                items: true,
                payments: true,
            },
            orderBy: {
                createdAt: 'desc',
            },
        });
        return orders.map((order) => {
            const totalAmount = Number(order.totalAmount);
            const paidAmount = order.payments.reduce((sum, p) => sum + Number(p.amount), 0);
            const dueAmount = totalAmount - paidAmount;
            return {
                id: order.id,
                sn: order.id.slice(-4),
                billNo: order.billNo || '',
                date: order.createdAt.toISOString(),
                customer: order.customer.fullName,
                mobile: order.customer.phone,
                orderStatus: order.status,
                amount: totalAmount,
                paidAmount: paidAmount,
                dueAmount: dueAmount,
                orderType: order.orderType || 'RX',
                title: order.title || '',
                priority: order.priority || 'Medium',
                notes: order.notes || '',
                expectedCompletionDate: order.expectedCompletionDate ? order.expectedCompletionDate.toISOString() : null,
                items: order.items.map((item) => ({
                    description: item.description,
                    sph: item.sph || '',
                    cyl: item.cyl || '',
                    axis: item.axis || '',
                    add: item.add || '',
                    eye: item.eye || '',
                    quantity: item.quantity,
                    unitPrice: Number(item.unitPrice),
                    lineTotal: Number(item.lineTotal),
                })),
            };
        });
    }
    static async createOrder(data) {
        const { orderType = 'RX', items = [], customerId: directCustomerId } = data;
        const billData = data.billData || {};
        const partyData = data.partyData || {};
        const financials = data.financials || {};
        const title = data.title || billData.title || null;
        const priority = data.priority || billData.priority || 'Medium';
        const notes = data.notes || billData.notes || null;
        const expectedCompletionDate = data.expectedCompletionDate || billData.expectedCompletionDate || null;
        const totalAmount = financials.totalAmount !== undefined ? Number(financials.totalAmount) : (data.totalAmount !== undefined ? Number(data.totalAmount) : 0);
        const paidAmount = financials.paidAmount !== undefined ? Number(financials.paidAmount) : (data.paidAmount !== undefined ? Number(data.paidAmount) : 0);
        const dueAmount = financials.dueAmount !== undefined ? Number(financials.dueAmount) : (data.dueAmount !== undefined ? Number(data.dueAmount) : 0);
        const billNo = billData.billNo || data.billNo || null;
        const billSeries = billData.billSeries || data.billSeries || null;
        const bookedBy = billData.bookedBy || data.bookedBy || null;
        const godown = billData.godown || data.godown || null;
        const status = financials.status || data.status || 'DRAFT';
        return await client_1.prisma.$transaction(async (tx) => {
            let finalCustomerId = directCustomerId;
            if (!finalCustomerId && partyData.contactNumber) {
                let customer = await tx.customer.findUnique({
                    where: { phone: partyData.contactNumber },
                });
                if (!customer) {
                    customer = await tx.customer.create({
                        data: {
                            fullName: partyData.partyAccount || 'Walk-in Customer',
                            phone: partyData.contactNumber,
                            email: partyData.email || null,
                        },
                    });
                }
                finalCustomerId = customer.id;
            }
            if (!finalCustomerId) {
                throw new Error('Customer identification required (customerId or partyData.contactNumber)');
            }
            let customer = await tx.customer.findUnique({
                where: { id: finalCustomerId },
            });
            if (!customer) {
                customer = await tx.customer.create({
                    data: {
                        id: finalCustomerId,
                        fullName: 'Walk-in Customer (Auto-Created)',
                        phone: '98765432' + Math.floor(10 + Math.random() * 90),
                    },
                });
            }
            const jobCard = await tx.jobCard.create({
                data: {
                    customerId: finalCustomerId,
                    status: parseJobCardStatus(status),
                    totalAmount: totalAmount,
                    paidAmount: paidAmount,
                    dueAmount: dueAmount,
                    billNo: billNo,
                    billSeries: billSeries,
                    orderType: orderType,
                    bookedBy: bookedBy,
                    godown: godown,
                    title: title,
                    priority: priority,
                    notes: notes,
                    expectedCompletionDate: expectedCompletionDate ? new Date(expectedCompletionDate) : null,
                    items: {
                        create: items.map((item) => {
                            const qty = Number(item.quantity ?? item.qty ?? 1);
                            const price = Number(item.unitPrice ?? item.salePrice ?? item.unit_price ?? 0);
                            const total = Number(item.lineTotal ?? item.totalAmount ?? item.line_total ?? (qty * price));
                            return {
                                productId: item.productId ?? item.combinationId ?? null,
                                description: item.description ?? item.itemName ?? 'Product',
                                quantity: qty,
                                unitPrice: price,
                                lineTotal: total,
                                sph: item.sph !== undefined && item.sph !== null ? String(item.sph) : null,
                                cyl: item.cyl !== undefined && item.cyl !== null ? String(item.cyl) : null,
                                axis: item.axis !== undefined && item.axis !== null ? String(item.axis) : null,
                                add: item.add !== undefined && item.add !== null ? String(item.add) : null,
                                eye: item.eye || null,
                            };
                        }),
                    },
                },
                include: {
                    customer: true,
                    items: true,
                },
            });
            if (paidAmount > 0) {
                let pType = 'CASH';
                const clientMode = String(data.paymentMode || data.paymentType || '').toUpperCase();
                if (clientMode.includes('UPI'))
                    pType = 'UPI';
                else if (clientMode.includes('CARD'))
                    pType = 'CARD';
                else if (clientMode.includes('BANK') || clientMode.includes('TRANSFER'))
                    pType = 'BANK_TRANSFER';
                await tx.payment.create({
                    data: {
                        jobCardId: jobCard.id,
                        amount: paidAmount,
                        paymentType: pType,
                    },
                });
            }
            const vendorProcurement = data.vendorProcurement;
            if (vendorProcurement && vendorProcurement.vendorId) {
                try {
                    const vendor = await tx.vendor.findUnique({
                        where: { id: vendorProcurement.vendorId }
                    });
                    const vendorName = vendor ? vendor.name : 'Selected Vendor';
                    const itemSummaries = items.map((it) => {
                        const power = [];
                        if (it.sph)
                            power.push(`SPH: ${it.sph}`);
                        if (it.cyl)
                            power.push(`CYL: ${it.cyl}`);
                        if (it.axis)
                            power.push(`AX: ${it.axis}`);
                        if (it.add)
                            power.push(`ADD: ${it.add}`);
                        const powerStr = power.length > 0 ? ` (${power.join(', ')})` : '';
                        return `- ${it.itemName || it.description || 'Lens'}${powerStr} [Qty: ${it.qty || it.quantity || 1}]`;
                    }).join('\n');
                    const firstItemName = items[0]?.itemName || items[0]?.description || 'Lens';
                    const restockQty = Number(vendorProcurement.restockQty || 10);
                    await tx.task.create({
                        data: {
                            title: `📦 RESTOCK ORDER: ${firstItemName} from ${vendorName}`,
                            description: `🚨 AUTO-GENERATED BACKORDER\nCustomer placed an order for 0-stock inventory. Procurement intent initiated:\n\n🛒 ORDER DETAILS:\n${itemSummaries}\n\n📈 VENDOR REPLENISHMENT PLAN:\nOrder ${restockQty} Units of above lens/specs from ${vendorName}.\nLinked JobCard: ${jobCard.billNo || jobCard.id}`,
                            status: 'PENDING',
                            priority: 'HIGH',
                            dueDate: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
                        }
                    });
                    console.log(`🚀 Auto-created Procurement Restock Task for JobCard: ${jobCard.id}`);
                }
                catch (taskErr) {
                    console.error('⚠️ Failed to auto-create procurement task:', taskErr);
                }
            }
            return jobCard;
        });
    }
    static async updateOrder(id, data) {
        const jobCard = await client_1.prisma.jobCard.findUnique({
            where: { id },
        });
        if (!jobCard) {
            throw new Error('Order (JobCard) not found');
        }
        const oldStatus = jobCard.status;
        const updateData = {};
        if (data.status !== undefined) {
            updateData.status = parseJobCardStatus(data.status);
        }
        if (data.totalAmount !== undefined) {
            updateData.totalAmount = Number(data.totalAmount);
        }
        if (data.paidAmount !== undefined) {
            updateData.paidAmount = Number(data.paidAmount);
        }
        if (data.dueAmount !== undefined) {
            updateData.dueAmount = Number(data.dueAmount);
        }
        const updated = await client_1.prisma.jobCard.update({
            where: { id },
            data: updateData,
            include: {
                customer: true,
                items: true,
            },
        });
        if (updateData.status !== undefined) {
            await (0, inventory_sync_util_1.syncInventoryOnStatusChange)(id, oldStatus, updateData.status);
        }
        return updated;
    }
}
exports.OrdersService = OrdersService;
//# sourceMappingURL=orders.service.js.map