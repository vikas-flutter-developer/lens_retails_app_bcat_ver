const QRCode = require('qrcode');
const path = require('path');
const fs = require('fs');

const items = [
  { sku: 'BL-LENS-002-R', filename: 'qr_BL_LENS_002_R.png' },
  { sku: 'BL-LENS-001', filename: 'qr_BL_LENS_001.png' },
  { sku: 'TEST-LENS-ZERO', filename: 'qr_TEST_LENS_ZERO.png' },
  { sku: 'BL-LENS-001-SAME', filename: 'qr_BL_LENS_001_SAME.png' },
  { sku: 'BL-LENS-001-L', filename: 'qr_BL_LENS_001_L.png' }
];

const downloadsFolder = 'C:\\Users\\Vikas\\Downloads';

async function generateAllQRs() {
  console.log('🚀 Generating QR codes for all items in your screenshot...');

  for (const item of items) {
    const outPath = path.join(downloadsFolder, item.filename);
    try {
      await QRCode.toFile(outPath, item.sku, {
        width: 350,
        margin: 2,
        color: {
          dark: '#000000',
          light: '#FFFFFF'
        }
      });
      console.log(`  ✓ Generated ${item.sku} -> ${item.filename}`);
    } catch (err) {
      console.error(`  ❌ Failed for ${item.sku}:`, err.message);
    }
  }
  console.log('\n✨ All 5 QR codes successfully saved to Downloads folder!');
}

generateAllQRs();
