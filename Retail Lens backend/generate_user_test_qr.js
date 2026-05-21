const QRCode = require('qrcode');
const path = require('path');
const os = require('os');

async function generate() {
  const userHome = os.homedir();
  const downloadsFolder = path.join(userHome, 'Downloads');

  const items = [
    { sku: 'BL-LENS-001-DIFF', filename: 'BAUSCH_LOMB_ULTRA_HD_QR.png' },
    { sku: 'PROD-LENS-001-GP2', filename: 'ANTI_REFLECTIVE_GP2_QR.png' },
    { sku: 'PROD-LENS-001', filename: 'ANTI_REFLECTIVE_STANDARD_QR.png' },
    { sku: 'PROD-LENS-001-GP4', filename: 'ANTI_REFLECTIVE_GP4_QR.png' },
    { sku: 'PROD-LENS-001-GP3', filename: 'ANTI_REFLECTIVE_GP3_QR.png' }
  ];

  for (const item of items) {
    const finalPath = path.join(downloadsFolder, item.filename);
    console.log(`🔍 Generating QR for SKU: "${item.sku}"...`);

    try {
      await QRCode.toFile(finalPath, item.sku, {
        width: 600,
        margin: 2,
        color: { dark: '#000000', light: '#FFFFFF' }
      });
      console.log(`✅ SUCCESS! Saved to: ${finalPath}`);
    } catch (err) {
      console.error(`❌ ERROR for ${item.sku}:`, err.message);
    }
  }
}

generate();
