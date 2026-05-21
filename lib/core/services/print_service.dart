import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PrintService {
  
  /// Generates and prints a premium, executive A4 Tax Invoice PDF
  static Future<void> printOrderReceipt(Map<String, dynamic> order, {String? businessName, String? address}) async {
    final pdf = pw.Document();
    
    // Extract Items
    final items = (order['items'] as List?) ?? [];

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 1. BUSINESS BRANDING HEADER
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(businessName ?? 'LENS RETAIL & OPTICALS', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
                      pw.SizedBox(height: 4),
                      pw.Text(address ?? '123 Main Street, Optical Plaza, Mumbai, MH - 400001', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                      pw.Text('Phone: +91 98765 43210  |  Email: contact@lensretail.com', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                      pw.Text('GSTIN: 27AAAAA1111A1Z1', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: const pw.BoxDecoration(color: PdfColors.indigo900, borderRadius: pw.BorderRadius.all(pw.Radius.circular(4))),
                        child: pw.Text('TAX INVOICE', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text('Invoice No: ${order['invoice'] ?? order['sn'] ?? 'N/A'}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Date: ${order['date'] ?? ''}', style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ],
              ),
              
              pw.SizedBox(height: 15),
              pw.Divider(thickness: 1.5, color: PdfColors.indigo900),
              pw.SizedBox(height: 10),
              
              // 2. METADATA SECTION: BILL TO vs BILL DETAILS
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('BILL TO:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
                        pw.SizedBox(height: 3),
                        pw.Text(order['customer'] ?? 'Walk-in Customer', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                        pw.Text('Phone: ${order['mobile'] ?? 'N/A'}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                        pw.Text('Address: India', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('BILL DETAILS:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
                        pw.SizedBox(height: 3),
                        pw.Text('Order Type: ${order['type'] ?? 'RX'}', style: const pw.TextStyle(fontSize: 9)),
                        if (order['remarks'] != null && order['remarks'].toString().isNotEmpty)
                          pw.Text('Remarks: ${order['remarks']}', style: const pw.TextStyle(fontSize: 9)),
                      ],
                    ),
                  ),
                ],
              ),
              
              pw.SizedBox(height: 20),
              
              // 3. ITEMIZED ITEMS TABLE
              _buildOrderTable(items, order),
              
              pw.SizedBox(height: 20),
              
              // 4. FINANCIAL SUMMARY CARD
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Terms and Conditions left side
                  pw.Expanded(
                    flex: 3,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Terms & Conditions:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
                        pw.Bullet(text: 'Lenses once processed cannot be returned or cancelled.', style: const pw.TextStyle(fontSize: 7)),
                        pw.Bullet(text: 'Please check your spectacles and visual comfort before leaving.', style: const pw.TextStyle(fontSize: 7)),
                        pw.Bullet(text: 'Guarantee/Warranty is subject to manufacturer terms.', style: const pw.TextStyle(fontSize: 7)),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 20),
                  // Summary boxes right side
                  pw.Expanded(
                    flex: 2,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                      children: [
                        _buildSummaryRow('Gross Total:', '₹${order['amount'] ?? '0.00'}'),
                        _buildSummaryRow('Paid Amount:', '₹${order['paidAmount'] ?? '0.00'}', isHighlight: true),
                        _buildSummaryRow('Due Balance:', '₹${order['dueAmount'] ?? '0.00'}', isDueHighlight: true),
                      ],
                    ),
                  ),
                ],
              ),
              
              pw.Spacer(),
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.SizedBox(height: 5),
              
              // 5. SIGNATORY FOOTER
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Thank you for choosing LENS RETAIL!', style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic, color: PdfColors.indigo900)),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.SizedBox(height: 10),
                      pw.Text('For LENS RETAIL & OPTICALS', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 20),
                      pw.Text('Authorized Signatory', style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Invoice_${order['invoice'] ?? 'Order'}.pdf',
    );
  }

  /// Helper to build the items table for order
  static pw.Widget _buildOrderTable(List<dynamic> items, Map<String, dynamic> order) {
    if (items.isNotEmpty) {
      return pw.TableHelper.fromTextArray(
        headers: ['Item/Lens Details', 'Eye', 'Sph', 'Cyl', 'Axis', 'Add', 'Qty', 'Price'],
        headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo900),
        cellStyle: const pw.TextStyle(fontSize: 8),
        columnWidths: {
          0: const pw.FlexColumnWidth(4), // Item Name
          1: const pw.FixedColumnWidth(25), // Eye
          2: const pw.FixedColumnWidth(30), // Sph
          3: const pw.FixedColumnWidth(30), // Cyl
          4: const pw.FixedColumnWidth(30), // Axis
          5: const pw.FixedColumnWidth(30), // Add
          6: const pw.FixedColumnWidth(25), // Qty
          7: const pw.FixedColumnWidth(45), // Price
        },
        data: items.map((item) {
          final eye = item['eye'] ?? 'RL';
          final itemName = item['description'] ?? item['itemName'] ?? item['lens'] ?? 'Optical Item';
          final price = item['unitPrice'] ?? item['salePrice'] ?? item['lineTotal'] ?? '0.00';
          return [
            itemName,
            eye,
            item['sph']?.toString() ?? '',
            item['cyl']?.toString() ?? '',
            item['axis']?.toString() ?? '',
            item['add']?.toString() ?? '',
            item['quantity']?.toString() ?? '1',
            '₹$price',
          ];
        }).toList(),
      );
    }
    
    // Fallback if no items list but we have flat eye data (Retro-compatibility)
    final r = order['eye_r'] as Map?;
    final l = order['eye_l'] as Map?;
    final List<List<String>> rows = [];
    
    if (r != null && (r['sph'] != null || r['cyl'] != null)) {
       rows.add(['Right Lens Details', 'R', r['sph']?.toString()??'', r['cyl']?.toString()??'', r['axis']?.toString()??'', r['add']?.toString()??'', '1', '']);
    }
    if (l != null && (l['sph'] != null || l['cyl'] != null)) {
       rows.add(['Left Lens Details',  'L', l['sph']?.toString()??'', l['cyl']?.toString()??'', l['axis']?.toString()??'', l['add']?.toString()??'', '1', '']);
    }

    if (rows.isNotEmpty) {
       return pw.TableHelper.fromTextArray(
        headers: ['Item Details', 'Eye', 'Sph', 'Cyl', 'Axis', 'Add', 'Qty', 'Price'],
        headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo900),
        cellStyle: const pw.TextStyle(fontSize: 8),
        data: rows,
      );
    }

    return pw.Text('No items details available');
  }

  /// Helper to build a summary table row
  static pw.Widget _buildSummaryRow(String label, String value, {bool isHighlight = false, bool isDueHighlight = false}) {
    final textColor = isDueHighlight ? PdfColors.red900 : (isHighlight ? PdfColors.green900 : PdfColors.black);
    final textWeight = (isHighlight || isDueHighlight) ? pw.FontWeight.bold : pw.FontWeight.normal;
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 9, fontWeight: textWeight)),
          pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: textColor)),
        ],
      ),
    );
  }

  /// Generates and prints a Ledger Statement PDF
  static Future<void> printLedgerStatement(List<dynamic> transactions, {String? customerName, String? dateRange, double? closingBalance}) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
             pw.Center(child: pw.Text('LEDGER STATEMENT', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900))),
             pw.SizedBox(height: 10),
             if (customerName != null) pw.Text('Customer: $customerName', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
             if (dateRange != null) pw.Text('Period: $dateRange', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
             pw.SizedBox(height: 15),
             
             pw.TableHelper.fromTextArray(
               headers: ['Date', 'Particulars', 'Debit (Out)', 'Credit (In)', 'Balance'],
               headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
               headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo900),
               cellStyle: const pw.TextStyle(fontSize: 8),
               columnWidths: {
                 0: const pw.FixedColumnWidth(60), // Date
                 1: const pw.FlexColumnWidth(2), // Particulars
                 2: const pw.FixedColumnWidth(60), // Debit
                 3: const pw.FixedColumnWidth(60), // Credit
                 4: const pw.FixedColumnWidth(70), // Balance
               },
               data: transactions.map((tx) {
                 return [
                   tx['date']?.toString() ?? '',
                   tx['description']?.toString() ?? tx['particulars'] ?? '',
                   tx['debit']?.toString() ?? '',
                   tx['credit']?.toString() ?? '',
                   tx['balance']?.toString() ?? '',
                 ];
               }).toList(),
             ),
             
             if (closingBalance != null) ...[
               pw.SizedBox(height: 15),
               pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
                 pw.Text('Closing Net Balance: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                 pw.Text('₹${closingBalance.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: PdfColors.indigo900)),
               ]),
             ]
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Ledger_${customerName ?? 'Statement'}.pdf',
    );
  }
}
