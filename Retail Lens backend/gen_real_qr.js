const QRCode = require('qrcode');
const path = require('path');

const id = 'job_kiran_6';
const outputPath = path.join('C:', 'Users', 'Vikas', 'Downloads', 'REAL-JOBCARD-KIRAN.png');

QRCode.toFile(outputPath, id, {
  color: {
    dark: '#000000',
    light: '#FFFFFF'
  },
  width: 600
}, function (err) {
  if (err) throw err;
  console.log('✅ PERFECT SCANNABLE QR CODE SAVED SUCCESSFULLY TO: ' + outputPath);
});
