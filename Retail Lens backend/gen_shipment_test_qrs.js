const QRCode = require('qrcode');
const path = require('path');

async function main() {
  console.log('🚀 Generating Scannable QR Pack for Shipment Verification...');

  const testCases = [
    {
      name: 'REAL-QR-SHIPMENT-shipment_perfect.png',
      content: 'BL-LENS-001,PROD-FRAME-001,PROD-CL-001,PROD-FRAM-101',
      desc: '100% Perfect Shipment Manifest'
    },
    {
      name: 'REAL-QR-SHIPMENT-shipment_missing.png',
      content: 'BL-LENS-001,PROD-FRAME-001',
      desc: 'Discrepancy (Missing 2 Core SKUs)'
    }
  ];

  for (const tc of testCases) {
    const outputPath = path.join('C:', 'Users', 'Vikas', 'Downloads', tc.name);
    
    await QRCode.toFile(outputPath, tc.content, {
      color: { dark: '#2C3E50', light: '#FFFFFF' },
      width: 600,
      margin: 3
    });
    
    console.log(`✅ Generated: ${tc.name}`);
    console.log(`   📄 Contains: "${tc.content}"`);
    console.log(`   💡 Purpose: ${tc.desc}\n`);
  }

  console.log('🎉 Perfect QR Pack has been written to your Downloads folder!');
}

main().catch(e => console.error('❌ Generation failed:', e));
