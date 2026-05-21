const { PrismaClient } = require('@prisma/client');
const fs = require('fs');
const prisma = new PrismaClient();

async function listLenses() {
  const lenses = await prisma.inventoryProduct.findMany({
    where: { kind: 'LENS' },
    orderBy: { sku: 'asc' }
  });

  let output = '--- LENS INVENTORY & POWER GROUPS ---\n';
  output += `Total lens configurations found: ${lenses.length}\n\n`;

  lenses.forEach((lens, index) => {
    output += `${index + 1}. [${lens.sku}] - ${lens.name}\n`;
    output += `   💰 Price: ₹${lens.salePrice} | 📦 Stock: ${lens.stockQuantity} Pcs\n`;
    
    if (lens.powerSpecs) {
      output += '   👓 Power Spec details:\n';
      const specs = typeof lens.powerSpecs === 'string' 
        ? JSON.parse(lens.powerSpecs) 
        : lens.powerSpecs;
        
      output += JSON.stringify(specs, null, 2).split('\n').map(line => '      ' + line).join('\n') + '\n';
    } else {
      output += '   👓 Power Spec details: None\n';
    }
    output += '---------------------------------------------------------\n';
  });

  fs.writeFileSync('lenses_clean.txt', output, 'utf8');
  console.log('Successfully wrote output to lenses_clean.txt');
}

listLenses()
  .catch(e => console.error('❌ Database Error:', e))
  .finally(async () => {
    await prisma.$disconnect();
  });
