import { InventoryKind } from '@prisma/client';
import * as path from 'path';
const { PDFParse } = require('pdf-parse');

export async function parsePdfInventory(pdfBuffer: Buffer): Promise<any[]> {
  try {
    let fontsPath = path.join(__dirname, '../../node_modules/pdfjs-dist/standard_fonts/').replace(/\\/g, '/');
    if (!fontsPath.endsWith('/')) {
      fontsPath += '/';
    }
    const parser = new PDFParse({
      data: pdfBuffer,
      standardFontDataUrl: fontsPath
    });
    const data = await parser.getText();
    const text: string = data.text || '';
    
    console.log(`[PDF Parser] Extracted raw text (length: ${text.length}):`);
    console.log('--- Raw Text Start ---');
    console.log(text);
    console.log('--- Raw Text End ---');
    
    const rawLines = text.split(/\r?\n/);
    console.log(`[PDF Parser] Number of raw lines: ${rawLines.length}`);

    function checkIsCompleteRow(line: string): boolean {
      const parts = line.split('\t').map(p => p.trim()).filter(Boolean);
      if (parts.length < 6) return false;
      for (let i = 1; i <= 3; i++) {
        const part = parts[parts.length - i];
        if (isNaN(parseFloat(part))) return false;
      }
      return true;
    }

    const rows: string[] = [];
    let pending = '';

    for (let i = 0; i < rawLines.length; i++) {
      const line = rawLines[i].trim();
      if (!line) continue;

      // Header/footer lines to ignore
      const isHeaderOrFooter = 
        line.includes('--') || 
        line.toLowerCase().startsWith('sno') || 
        line.toLowerCase().startsWith('prod name') ||
        line.toLowerCase().startsWith('stock') ||
        line.toLowerCase().startsWith('in_hand') ||
        line.toLowerCase().startsWith('(+ opng') ||
        line.toLowerCase().startsWith('value barcode') ||
        line.toLowerCase().startsWith('sadguru') ||
        line.toLowerCase().startsWith('shop no.') ||
        line.toLowerCase().startsWith('universal item') ||
        /^\d{6}$/.test(line); // postal code (e.g. 400101)

      if (isHeaderOrFooter) {
        continue;
      }

      if (!pending) {
        pending = line;
      } else {
        const isPendingComplete = checkIsCompleteRow(pending);
        // Matches a serial number followed by a space or tab and then letters/words
        const isNewRowStart = line.match(/^\d+(?:\s+|\t+)([a-zA-Z].*)/);

        if (isPendingComplete && isNewRowStart) {
          rows.push(pending);
          pending = line;
        } else {
          pending += ' ' + line;
        }
      }
    }
    if (pending) {
      rows.push(pending);
    }

    console.log(`[PDF Parser] Assembled rows count: ${rows.length}`);
    const products: any[] = [];
    
    for (const row of rows) {
      const parts = row.split('\t').map(p => p.trim()).filter(Boolean);
      if (parts.length < 6) {
        continue;
      }

      // SNo and part of Name might be combined in parts[0]
      const firstPart = parts[0];
      const snoMatch = firstPart.match(/^(\d+)(?:\s+|\t+)(.*)$/);
      let sno = NaN;
      let firstPartOfName = '';
      
      if (snoMatch) {
        sno = parseInt(snoMatch[1], 10);
        firstPartOfName = snoMatch[2].trim();
      } else {
        sno = parseInt(firstPart, 10);
      }

      if (isNaN(sno)) continue; // Must have a valid SNo

      // Standard columns at the end:
      // - Sale Prc (end)
      // - Pur Prc (end - 1)
      // - Qty (end - 2)
      // - Stock Value & Barcode (end - 3)
      // - Stock In_Hand (end - 4)
      // - Unit (end - 5)
      
      const salePriceStr = parts[parts.length - 1];
      const purchasePriceStr = parts[parts.length - 2];
      const qtyStr = parts[parts.length - 3];
      const barcodeAndValueStr = parts[parts.length - 4];
      const stockInHandStr = parts[parts.length - 5];

      // Parse prices and quantities
      const salePrice = parseFloat(salePriceStr) || 0;
      const purchasePrice = parseFloat(purchasePriceStr) || 0;
      
      // Stock Quantity: The quantity to add is in the 'Qty' column or 'Stock In_Hand'
      let stockQuantity = parseFloat(qtyStr) || 0;
      if (stockQuantity === 0 && stockInHandStr) {
        stockQuantity = parseFloat(stockInHandStr) || 0;
      }
      
      // Parse Barcode
      let barcode = '';
      if (barcodeAndValueStr) {
        const barcodeParts = barcodeAndValueStr.split(/\s+/);
        if (barcodeParts.length > 1) {
          barcode = barcodeParts[1];
        } else {
          barcode = barcodeParts[0];
        }
      }
      if (barcode === 'NA') {
        barcode = '';
      }

      // Extract fullName
      const nameParts: string[] = [];
      if (firstPartOfName) {
        nameParts.push(firstPartOfName);
      }
      // The name parts go up to parts.length - 7 (before Unit at parts.length - 6)
      const endIndexForName = parts.length - 7;
      for (let idx = 1; idx <= endIndexForName; idx++) {
        nameParts.push(parts[idx]);
      }
      
      let fullName = nameParts.join(' ').trim();
      fullName = fullName.replace(/^\d+\s+/, ''); // strip leading sno if still there

      // Determine Kind (FRAME, LENS, ACCESSORY)
      let kind: InventoryKind = InventoryKind.ACCESSORY;
      const upperRow = row.toUpperCase();
      if (upperRow.includes('FRAME')) {
        kind = InventoryKind.FRAME;
      } else if (upperRow.includes('LENS')) {
        kind = InventoryKind.LENS;
      }

      // SKU / Barcode
      let sku = barcode;
      if (!sku) {
        // Try to find a model code in name
        const tokens = fullName.split(/\s+/);
        let bestSku = '';
        let bestScore = -1;
        for (const t of tokens) {
          const u = t.toUpperCase();
          if (u === 'FRAME' || u === 'LENS' || u === 'ACCESSORY' || u === 'GLASS') continue;
          
          const hasLetters = /[a-zA-Z]/.test(t);
          const hasDigits = /[0-9]/.test(t);
          const isUpper = t === t.toUpperCase();
          
          let score = 0;
          if (t.length >= 4 && t.length <= 15) {
            if (hasLetters && hasDigits) score = 10;
            else if (hasDigits) score = 7;
            else if (isUpper) score = 5;
          }
          if (score > bestScore && score > 0) {
            bestScore = score;
            bestSku = t;
          }
        }
        sku = bestSku;
      }
      if (!sku) {
        const cleanName = fullName.replace(/[^a-zA-Z0-9]/g, '').substring(0, 5).toUpperCase();
        const rand = Math.floor(Math.random() * 100000);
        sku = `GEN-PDF-${cleanName || 'ITEM'}-${rand}`;
      }

      products.push({
        sku,
        name: fullName,
        kind,
        stockQuantity,
        purchasePrice,
        salePrice
      });
    }

    return products;
  } catch (e) {
    console.error('Error parsing PDF text:', e);
    throw new Error('Failed to parse PDF file text content.');
  }
}
