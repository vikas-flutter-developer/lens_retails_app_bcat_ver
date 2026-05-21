const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

function safeOffset(value, offset) {
  const num = parseFloat(value || "0");
  if (isNaN(num)) return value;
  const res = num + offset;
  // Keep formatting nice (e.g. remove extra decimals if it's integer)
  return String(Number(res.toFixed(2))); 
}

async function generateAllVariations() {
  console.log('🔍 Fetching current lens products...');
  
  const lenses = await prisma.inventoryProduct.findMany({
    where: { kind: 'LENS' }
  });

  console.log(`Found ${lenses.length} existing lenses. Generating variations...\n`);

  let createdCount = 0;
  let skippedCount = 0;

  for (const base of lenses) {
    // Skip products that already have our generated suffixes to avoid double generation
    if (base.sku.endsWith('-L') || 
        base.sku.endsWith('-R') || 
        base.sku.endsWith('-SAME') || 
        base.sku.endsWith('-DIFF')) {
      console.log(`⏩ Skipping already-generated variation: ${base.sku}`);
      continue;
    }

    // Extract base spec
    let baseSpec = base.powerSpecs;
    if (typeof baseSpec === 'string') {
      baseSpec = JSON.parse(baseSpec);
    }

    if (!baseSpec || (!baseSpec.leftEye && !baseSpec.rightEye)) {
      console.log(`⚠️ Lens ${base.sku} has no valid powerSpecs. Skipping...`);
      continue;
    }

    const baseLeft = baseSpec.leftEye || baseSpec.rightEye;
    const baseRight = baseSpec.rightEye || baseSpec.leftEye;

    const variationsConfig = [
      {
        suffix: '-L',
        nameSuffix: ' (Left Only)',
        power: {
          leftEye: { ...baseLeft },
          rightEye: null
        }
      },
      {
        suffix: '-R',
        nameSuffix: ' (Right Only)',
        power: {
          leftEye: null,
          rightEye: { ...baseRight }
        }
      },
      {
        suffix: '-SAME',
        nameSuffix: ' (Both Eyes Same)',
        power: {
          leftEye: { ...baseLeft },
          rightEye: { ...baseLeft }
        }
      },
      {
        suffix: '-DIFF',
        nameSuffix: ' (Both Eyes Diff)',
        power: {
          leftEye: { ...baseLeft },
          rightEye: {
            ...baseRight,
            sphFrom: safeOffset(baseRight.sphFrom, 2),
            sphTo: safeOffset(baseRight.sphTo, 2),
            cylFrom: safeOffset(baseRight.cylFrom, 1),
            cylTo: safeOffset(baseRight.cylTo, 1),
            // Offset axis if exists
            axis: baseRight.axis === "180" ? "90" : "180"
          }
        }
      }
    ];

    console.log(`Creating variations for base product [${base.sku}] - ${base.name}...`);

    for (const variant of variationsConfig) {
      const newSku = `${base.sku}${variant.suffix}`;
      const newName = `${base.name}${variant.nameSuffix}`;
      
      try {
        await prisma.inventoryProduct.create({
          data: {
            sku: newSku,
            name: newName,
            kind: base.kind,
            stockQuantity: Math.max(20, Math.floor(Math.random() * 100)), // Assign random stock for testing variety
            reorderLevel: base.reorderLevel,
            salePrice: base.salePrice,
            vendorId: base.vendorId,
            powerSpecs: variant.power
          }
        });
        console.log(`  ✅ Created: ${newSku}`);
        createdCount++;
      } catch (err) {
        if (err.code === 'P2002') {
          console.log(`  ⏩ Exists: ${newSku} (skipped)`);
          skippedCount++;
        } else {
          console.error(`  ❌ Error creating ${newSku}:`, err.message);
        }
      }
    }
  }

  console.log(`\n✨ Operation Complete!`);
  console.log(`   🎉 Successfully Created: ${createdCount} variants`);
  console.log(`   ⏩ Skipped/Already Existed: ${skippedCount}`);
}

generateAllVariations()
  .catch(e => console.error('❌ CRITICAL ERROR:', e))
  .finally(async () => {
    await prisma.$disconnect();
  });
