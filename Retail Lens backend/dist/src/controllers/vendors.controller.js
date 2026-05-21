"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.VendorsController = void 0;
const vendors_service_1 = require("../services/vendors.service");
const response_util_1 = require("../utils/response.util");
const client_1 = require("../prisma/client");
class VendorsController {
    static async getVendors(req, res) {
        try {
            const vendors = await vendors_service_1.VendorsService.getAllVendors();
            const data = vendors.map((v) => {
                const hashCode = (str) => {
                    let hash = 0;
                    for (let i = 0; i < str.length; i++) {
                        hash = str.charCodeAt(i) + ((hash << 5) - hash);
                    }
                    return Math.abs(hash);
                };
                const hash = hashCode(v.id);
                let gstin = `27AAACB${1000 + (hash % 9000)}F1Z${hash % 9}`;
                let displayAlias = v.alias || '';
                if (v.alias && v.alias.startsWith('{')) {
                    try {
                        const parsed = JSON.parse(v.alias);
                        if (parsed.gstin)
                            gstin = parsed.gstin;
                        displayAlias = parsed.userAlias || '';
                    }
                    catch (e) {
                    }
                }
                return {
                    id: v.id,
                    accountId: v.accountId,
                    name: v.name,
                    printName: v.printName,
                    alias: displayAlias,
                    group: v.groupName,
                    station: v.station,
                    contactPerson: v.contactPerson,
                    phone: v.phone,
                    email: v.email,
                    accountType: v.accountType,
                    gstin
                };
            });
            return (0, response_util_1.sendSuccess)(res, { data }, 'Vendors fetched successfully');
        }
        catch (error) {
            console.error('Error fetching vendors:', error);
            return (0, response_util_1.sendError)(res, error.message || 'Failed to fetch vendors');
        }
    }
    static async createVendor(req, res) {
        try {
            const { name, printName, accountId, alias, group, groupName, station, contactPerson, phone, email, accountType, address, dob, gstin } = req.body;
            if (!name || !accountId) {
                return (0, response_util_1.sendError)(res, 'Name and accountId are required', 400);
            }
            const serializedAlias = JSON.stringify({
                userAlias: alias || '',
                address: address || '',
                dob: dob || '',
                gstin: gstin || ''
            });
            const vendor = await vendors_service_1.VendorsService.createOrUpdateVendor({
                name,
                printName,
                accountId,
                alias: serializedAlias,
                groupName: group || groupName,
                station,
                contactPerson,
                phone,
                email,
                accountType
            });
            return (0, response_util_1.sendSuccess)(res, {
                data: {
                    id: vendor.id,
                    accountId: vendor.accountId,
                    name: vendor.name
                }
            }, 'Vendor created successfully', 201);
        }
        catch (error) {
            console.error('Error creating vendor:', error);
            if (error.code === 'P2002') {
                return (0, response_util_1.sendError)(res, 'Vendor with this Account ID already exists', 400);
            }
            return (0, response_util_1.sendError)(res, error.message || 'Failed to create vendor');
        }
    }
    static async getVendorById(req, res) {
        try {
            const { id } = req.params;
            const vendors = await vendors_service_1.VendorsService.getAllVendors();
            const vendor = vendors.find((v) => v.id === id);
            if (!vendor) {
                return (0, response_util_1.sendError)(res, 'Vendor not found', 404);
            }
            const uniqueVendorData = {
                'VND-1001': {
                    totalOrders: 38,
                    outstanding: 6500,
                    dob: "08-Jan-1990",
                    address: "Lawrence & Mayo Complex, MG Road, Ernakulam, Kerala, India",
                    gstin: "09AAACB1234F1Z1"
                },
                'VND-1002': {
                    totalOrders: 28,
                    outstanding: 12000,
                    dob: "12-Aug-1980",
                    address: "Bausch & Lomb Building, Block C, Sector 62, Noida, UP, India",
                    gstin: "27AAACB5678F1Z2"
                },
                'VND-1003': {
                    totalOrders: 18,
                    outstanding: 9500,
                    dob: "24-Nov-1978",
                    address: "Carl Zeiss Vision HQ, 4th Block, Koramangala, Bengaluru, India",
                    gstin: "29AAACB9012F1Z3"
                },
                'VND-1004': {
                    totalOrders: 42,
                    outstanding: 15000,
                    dob: "15-May-1985",
                    address: "Essilor Tower, 12th Main Road, Gariahat, Kolkata, West Bengal, India",
                    gstin: "19AAACB3456F1Z4"
                }
            };
            const accountId = vendor.accountId;
            let totalOrders = 0;
            let outstanding = 0;
            let dob = "15-May-1985";
            let address = "Not set";
            let gstin = "27AAACB1000F1Z0";
            let displayAlias = vendor.alias || '';
            const matched = uniqueVendorData[accountId];
            if (matched) {
                totalOrders = matched.totalOrders;
                outstanding = matched.outstanding;
                dob = matched.dob;
                address = matched.address;
                gstin = matched.gstin;
            }
            if (vendor.alias && vendor.alias.startsWith('{')) {
                try {
                    const parsed = JSON.parse(vendor.alias);
                    if (parsed.address)
                        address = parsed.address;
                    if (parsed.dob)
                        dob = parsed.dob;
                    if (parsed.gstin)
                        gstin = parsed.gstin;
                    if (parsed.totalOrders !== undefined)
                        totalOrders = parsed.totalOrders;
                    if (parsed.outstanding !== undefined)
                        outstanding = parsed.outstanding;
                    displayAlias = parsed.userAlias || '';
                }
                catch (e) {
                }
            }
            const data = {
                id: vendor.id,
                accountId: vendor.accountId,
                name: vendor.name,
                printName: vendor.printName,
                alias: displayAlias,
                group: vendor.groupName,
                station: vendor.station,
                contactPerson: vendor.contactPerson || 'Admin Manager',
                phone: vendor.phone || '+91 98765 43210',
                email: vendor.email || 'contact@lab.com',
                accountType: vendor.accountType,
                address,
                dob,
                totalOrders,
                outstanding,
                gstin
            };
            return (0, response_util_1.sendSuccess)(res, { data }, 'Vendor profile fetched successfully');
        }
        catch (error) {
            console.error('Error fetching vendor profile:', error);
            return (0, response_util_1.sendError)(res, error.message || 'Failed to fetch vendor profile');
        }
    }
    static async getVendorLedger(req, res) {
        try {
            const { id } = req.params;
            const vendors = await vendors_service_1.VendorsService.getAllVendors();
            const vendor = vendors.find((v) => v.id === id);
            if (!vendor) {
                return (0, response_util_1.sendError)(res, 'Vendor not found', 404);
            }
            const accountId = vendor.accountId;
            let outstandingBalance = 0;
            let transactions = [];
            if (accountId === 'VND-1001') {
                outstandingBalance = 6500;
                transactions = [
                    {
                        date: "01-Apr-2026",
                        particulars: "Opening Balance",
                        voucherType: "Opening",
                        voucherNo: "-",
                        debit: 0,
                        credit: 14500,
                        balance: 14500,
                        type: "Cr"
                    },
                    {
                        date: "08-Apr-2026",
                        particulars: "Payment made via UPI",
                        voucherType: "Payment",
                        voucherNo: "UPI-48192837",
                        debit: 12000,
                        credit: 0,
                        balance: 2500,
                        type: "Cr"
                    },
                    {
                        date: "05-May-2026",
                        particulars: "Invoice #INV-2026-081",
                        voucherType: "Purchase",
                        voucherNo: "PUR-081",
                        debit: 0,
                        credit: 4000,
                        balance: 6500,
                        type: "Cr"
                    }
                ];
            }
            else if (accountId === 'VND-1002') {
                outstandingBalance = 12000;
                transactions = [
                    {
                        date: "01-Apr-2026",
                        particulars: "Opening Balance",
                        voucherType: "Opening",
                        voucherNo: "-",
                        debit: 0,
                        credit: 24000,
                        balance: 24000,
                        type: "Cr"
                    },
                    {
                        date: "15-Apr-2026",
                        particulars: "Payment made via Cheque",
                        voucherType: "Payment",
                        voucherNo: "CHQ-104829",
                        debit: 12000,
                        credit: 0,
                        balance: 12000,
                        type: "Cr"
                    }
                ];
            }
            else if (accountId === 'VND-1003') {
                outstandingBalance = 9500;
                transactions = [
                    {
                        date: "01-Apr-2026",
                        particulars: "Opening Balance",
                        voucherType: "Opening",
                        voucherNo: "-",
                        debit: 0,
                        credit: 9500,
                        balance: 9500,
                        type: "Cr"
                    }
                ];
            }
            else if (accountId === 'VND-1004') {
                outstandingBalance = 15000;
                transactions = [
                    {
                        date: "01-Apr-2026",
                        particulars: "Opening Balance",
                        voucherType: "Opening",
                        voucherNo: "-",
                        debit: 0,
                        credit: 15000,
                        balance: 15000,
                        type: "Cr"
                    }
                ];
            }
            else {
                outstandingBalance = 0;
                transactions = [
                    {
                        date: "01-Apr-2026",
                        particulars: "Opening Balance",
                        voucherType: "Opening",
                        voucherNo: "-",
                        debit: 0,
                        credit: 0,
                        balance: 0,
                        type: "Cr"
                    }
                ];
            }
            if (vendor.alias && vendor.alias.startsWith('{')) {
                try {
                    const parsed = JSON.parse(vendor.alias);
                    if (parsed.outstanding !== undefined) {
                        outstandingBalance = parsed.outstanding;
                    }
                    if (parsed.payments !== undefined && Array.isArray(parsed.payments)) {
                        transactions = [...transactions, ...parsed.payments];
                    }
                }
                catch (e) {
                }
            }
            const data = {
                vendorId: vendor.id,
                vendorName: vendor.name,
                outstandingBalance,
                transactions
            };
            return (0, response_util_1.sendSuccess)(res, { data }, 'Vendor ledger fetched successfully');
        }
        catch (error) {
            console.error('Error fetching vendor ledger:', error);
            return (0, response_util_1.sendError)(res, error.message || 'Failed to fetch vendor ledger');
        }
    }
    static async deleteVendor(req, res) {
        try {
            const { id } = req.params;
            await vendors_service_1.VendorsService.deleteVendor(id);
            return (0, response_util_1.sendSuccess)(res, {}, 'Vendor deleted successfully');
        }
        catch (error) {
            console.error('Error deleting vendor:', error);
            if (error.code === 'P2025') {
                return (0, response_util_1.sendError)(res, 'Vendor not found', 404);
            }
            return (0, response_util_1.sendError)(res, error.message || 'Failed to delete vendor');
        }
    }
    static async payVendor(req, res) {
        try {
            const { id } = req.params;
            const { amount, paymentMode, referenceNumber } = req.body;
            const vendors = await vendors_service_1.VendorsService.getAllVendors();
            const vendor = vendors.find((v) => v.id === id);
            if (!vendor) {
                return (0, response_util_1.sendError)(res, 'Vendor not found', 404);
            }
            const uniqueVendorData = {
                'VND-1001': { totalOrders: 38, outstanding: 6500, dob: "08-Jan-1990", address: "Lawrence & Mayo Complex, MG Road, Ernakulam, Kerala, India", gstin: "09AAACB1234F1Z1" },
                'VND-1002': { totalOrders: 28, outstanding: 12000, dob: "12-Aug-1980", address: "Bausch & Lomb Building, Block C, Sector 62, Noida, UP, India", gstin: "27AAACB5678F1Z2" },
                'VND-1003': { totalOrders: 18, outstanding: 9500, dob: "24-Nov-1978", address: "Carl Zeiss Vision HQ, 4th Block, Koramangala, Bengaluru, India", gstin: "29AAACB9012F1Z3" },
                'VND-1004': { totalOrders: 42, outstanding: 15000, dob: "15-May-1985", address: "Essilor Tower, 12th Main Road, Gariahat, Kolkata, West Bengal, India", gstin: "19AAACB3456F1Z4" }
            };
            const accountId = vendor.accountId;
            let totalOrders = 0;
            let outstanding = 0;
            let dob = "15-May-1985";
            let address = "Not set";
            let gstin = "27AAACB1000F1Z0";
            let userAlias = '';
            let payments = [];
            const matched = uniqueVendorData[accountId];
            if (matched) {
                totalOrders = matched.totalOrders;
                outstanding = matched.outstanding;
                dob = matched.dob;
                address = matched.address;
                gstin = matched.gstin;
            }
            if (vendor.alias && vendor.alias.startsWith('{')) {
                try {
                    const parsed = JSON.parse(vendor.alias);
                    if (parsed.address)
                        address = parsed.address;
                    if (parsed.dob)
                        dob = parsed.dob;
                    if (parsed.gstin)
                        gstin = parsed.gstin;
                    if (parsed.totalOrders !== undefined)
                        totalOrders = parsed.totalOrders;
                    if (parsed.outstanding !== undefined)
                        outstanding = parsed.outstanding;
                    if (parsed.payments !== undefined)
                        payments = parsed.payments;
                    userAlias = parsed.userAlias || '';
                }
                catch (e) {
                }
            }
            const payAmount = Number(amount);
            const newOutstanding = Math.max(0, outstanding - payAmount);
            const newPayment = {
                date: new Date().toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' }).replace(/ /g, '-'),
                particulars: `Payment made via ${paymentMode}`,
                voucherType: 'Payment',
                voucherNo: referenceNumber || '-',
                debit: payAmount,
                credit: 0,
                balance: newOutstanding,
                type: 'Cr'
            };
            payments.push(newPayment);
            const updatedAlias = JSON.stringify({
                address,
                dob,
                gstin,
                totalOrders,
                outstanding: newOutstanding,
                payments,
                userAlias
            });
            await client_1.prisma.vendor.update({
                where: { id },
                data: { alias: updatedAlias }
            });
            return (0, response_util_1.sendSuccess)(res, {
                success: true,
                message: 'Payment recorded successfully',
                data: {
                    vendorId: id,
                    vendorName: vendor.name,
                    amountPaid: payAmount,
                    paymentMode,
                    referenceNumber: referenceNumber || '-',
                    timestamp: new Date().toISOString()
                }
            }, 'Vendor payment processed successfully');
        }
        catch (error) {
            console.error('Error processing vendor payment:', error);
            return (0, response_util_1.sendError)(res, error.message || 'Failed to process vendor payment');
        }
    }
    static async updateVendor(req, res) {
        try {
            const { id } = req.params;
            const { name, contactPerson, phone, email, address, dob, gstin, totalOrders, outstanding } = req.body;
            const vendor = await client_1.prisma.vendor.findUnique({
                where: { id: id }
            });
            if (!vendor) {
                return (0, response_util_1.sendError)(res, 'Vendor not found', 404);
            }
            let currentAddress = "Not set";
            let currentDob = "15-May-1985";
            let currentGstin = "27AAACB1000F1Z0";
            let currentTotalOrders = 0;
            let currentOutstanding = 0;
            let userAlias = '';
            let payments = [];
            if (vendor.alias && vendor.alias.startsWith('{')) {
                try {
                    const parsed = JSON.parse(vendor.alias);
                    if (parsed.address)
                        currentAddress = parsed.address;
                    if (parsed.dob)
                        currentDob = parsed.dob;
                    if (parsed.gstin)
                        currentGstin = parsed.gstin;
                    if (parsed.totalOrders !== undefined)
                        currentTotalOrders = parsed.totalOrders;
                    if (parsed.outstanding !== undefined)
                        currentOutstanding = parsed.outstanding;
                    if (parsed.payments !== undefined)
                        payments = parsed.payments;
                    userAlias = parsed.userAlias || '';
                }
                catch (e) {
                }
            }
            const updatedAlias = JSON.stringify({
                address: address !== undefined ? address : currentAddress,
                dob: dob !== undefined ? dob : currentDob,
                gstin: gstin !== undefined ? gstin : currentGstin,
                totalOrders: totalOrders !== undefined ? Number(totalOrders) : currentTotalOrders,
                outstanding: outstanding !== undefined ? Number(outstanding) : currentOutstanding,
                payments,
                userAlias
            });
            const updatedVendor = await client_1.prisma.vendor.update({
                where: { id },
                data: {
                    name: name !== undefined ? name : vendor.name,
                    contactPerson: contactPerson !== undefined ? contactPerson : vendor.contactPerson,
                    phone: phone !== undefined ? phone : vendor.phone,
                    email: email !== undefined ? email : vendor.email,
                    alias: updatedAlias
                }
            });
            return (0, response_util_1.sendSuccess)(res, {
                success: true,
                message: 'Vendor updated successfully',
                data: {
                    id: updatedVendor.id,
                    name: updatedVendor.name,
                    accountId: updatedVendor.accountId,
                    phone: updatedVendor.phone,
                    email: updatedVendor.email,
                    contactPerson: updatedVendor.contactPerson,
                    address: address !== undefined ? address : currentAddress,
                    dob: dob !== undefined ? dob : currentDob,
                    gstin: gstin !== undefined ? gstin : currentGstin,
                    totalOrders: totalOrders !== undefined ? Number(totalOrders) : currentTotalOrders,
                    outstanding: outstanding !== undefined ? Number(outstanding) : currentOutstanding
                }
            }, 'Vendor details updated successfully');
        }
        catch (error) {
            console.error('Error updating vendor:', error);
            return (0, response_util_1.sendError)(res, error.message || 'Failed to update vendor');
        }
    }
}
exports.VendorsController = VendorsController;
//# sourceMappingURL=vendors.controller.js.map