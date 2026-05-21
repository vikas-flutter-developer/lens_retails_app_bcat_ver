import { prisma } from '../prisma/client';

export class VendorsService {
  static async getAllVendors() {
    return await (prisma as any).vendor.findMany({
      orderBy: {
        name: 'asc',
      },
    });
  }

  static async createOrUpdateVendor(data: any) {
    const { accountId, ...rest } = data;
    
    return await (prisma as any).vendor.upsert({
      where: { accountId },
      update: rest,
      create: { accountId, ...rest },
    });
  }

  static async deleteVendor(id: string) {
    return await (prisma as any).vendor.delete({
      where: { id },
    });
  }
}
