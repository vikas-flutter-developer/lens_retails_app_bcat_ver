const QRCode = require('qrcode');
const path = require('path');

const text = 'PROD-LENS-001-GP4';
const outputPath = path.join(__dirname, 'test_qr_GP4.png');

QRCode.toFile(outputPath, text, {
    color: {
        dark: '#000000',
        light: '#FFFFFF'
    },
    width: 500
}, function (err) {
    if (err) throw err;
    console.log('QR code generated successfully at:', outputPath);
});
