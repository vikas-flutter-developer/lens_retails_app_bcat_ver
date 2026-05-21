const { PrismaClient } = require('@prisma/client');
const QRCode = require('qrcode');
const path = require('path');
const fs = require('fs');

const prisma = new PrismaClient();

async function main() {
  const jobs = await prisma.jobCard.findMany({
    take: 5,
    select: { id: true, billNo: true, status: true },
    orderBy: { createdAt: 'desc' }
  });
  
  console.log(`Generating real scannable QRs for ${jobs.length} active Job Cards...`);
  
  for (const job of jobs) {
    const safeId = job.id.replace(/[^a-z0-9_]/gi, '_');
    const filename = `REAL-QR-JOB-${safeId}.png`;
    const outputPath = path.join('C:', 'Users', 'Vikas', 'Downloads', filename);
    
    await QRCode.toFile(outputPath, job.id, {
      color: { dark: '#000000', light: '#FFFFFF' },
      width: 600,
      margin: 2
    });
    
    console.log(`✅ Generated: ${filename} (Status: ${job.status})`);
  }
}

main()
  .catch(e => console.error(e))
  .finally(async () => await prisma.$disconnect());
