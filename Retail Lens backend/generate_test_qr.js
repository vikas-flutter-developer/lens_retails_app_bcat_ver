const QRCode = require('qrcode');
const path = require('path');

async function generateQR() {
  const sku = 'TEST-LENS-ZERO';
  const outputPath = path.join(__dirname, 'test_lens_zero_qr.png');
  
  console.log(`🔍 Generating QR Code image for SKU: "${sku}"...`);
  
  try {
    await QRCode.toFile(outputPath, sku, {
      color: {
        dark: '#000000',
        light: '#FFFFFF'
      },
      width: 400,
      margin: 2
    });
    
    console.log(`✅ QR Code saved successfully to: ${outputPath}`);
  } catch (err) {
    console.error('❌ Failed to generate QR code:', err.message);
  }
}

generateQR();
