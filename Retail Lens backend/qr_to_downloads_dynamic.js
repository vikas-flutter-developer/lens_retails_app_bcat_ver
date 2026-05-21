const QRCode = require('qrcode');
const path = require('path');
const os = require('os');

async function generateToExactDownloads() {
  // os.homedir() dynamically resolves to C:\Users\Vikas on Windows
  const userHome = os.homedir();
  const downloadsFolder = path.join(userHome, 'Downloads');
  const finalPath = path.join(downloadsFolder, 'ZERO_STOCK_TEST_QR.png');
  
  console.log(`🚀 Dynamically resolved Downloads path: ${downloadsFolder}`);
  console.log(`🔍 Generating QR for SKU: "TEST-LENS-ZERO"...`);

  try {
    await QRCode.toFile(finalPath, 'TEST-LENS-ZERO', {
      width: 500,
      margin: 2,
      color: {
        dark: '#000000',
        light: '#FFFFFF'
      }
    });
    console.log(`✅ SUCCESS! Generated and saved directly to: ${finalPath}`);
  } catch (err) {
    console.error(`❌ ERROR:`, err.message);
  }
}

generateToExactDownloads();
