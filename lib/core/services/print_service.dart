import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PrintService {
  
  /// Generates and prints an Order Receipt PDF
  static Future<void> printOrderReceipt(Map<String, dynamic> order, {String? businessName, String? address}) async {
    final pdf = pw.Document();
    
    // Extract Items
    final items = (order['items'] as List?) ?? [];
    // If empty items, maybe check raw?
    // But UI usually passes processed order map.

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // Receipt format (80mm) or A4? Default A4 is better for most.
        // Let's use A4 for now as it's standard, or roll80 if thermal.
        // Usually mobile apps print A4 via AirPrint/CloudPrint.
        // If thermal, user needs specific package. 'printing' handles system dialog.
        // Let's stick to standard format that adapts.
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(child: pw.Text(businessName ?? 'RETAIL FLOW', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold))),
              if (address != null) pw.Center(child: pw.Text(address, style: const pw.TextStyle(fontSize: 10))),
              pw.Divider(),
              
              // Order Info
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text('Invoice: ${order['invoice'] ?? order['sn'] ?? 'N/A'}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.Text('Date: ${order['date'] ?? ''}', style: const pw.TextStyle(fontSize: 10)),
              ]),
              pw.Text('Customer: ${order['customer'] ?? 'Walk-in'}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              if (order['refNo'] != null) pw.Text('Ref: ${order['refNo']}', style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 10),
              
              // Items Table
              _buildOrderTable(items, order),

              pw.SizedBox(height: 10),
              pw.Divider(),
              
              // Totals
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text('Total Amount: ', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.Text('${order['amount'] ?? '0.00'}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              
              pw.SizedBox(height: 20),
              pw.Center(child: pw.Text('Thank you for your business!', style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic))),
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
    // If we have items list, use it
    if (items.isNotEmpty) {
      return pw.TableHelper.fromTextArray(
        headers: ['Item/Lens', 'Eye', 'Sph', 'Cyl', 'Axis', 'Add', 'Qty', 'Price'],
        headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        cellStyle: const pw.TextStyle(fontSize: 8),
        columnWidths: {
          0: const pw.FlexColumnWidth(3), // Item Name
          1: const pw.FixedColumnWidth(25), // Eye
          2: const pw.FixedColumnWidth(25), // Sph
          3: const pw.FixedColumnWidth(25), // Cyl
          4: const pw.FixedColumnWidth(25), // Axis
          5: const pw.FixedColumnWidth(25), // Add
          6: const pw.FixedColumnWidth(20), // Qty
          7: const pw.FixedColumnWidth(35), // Price
        },
        data: items.map((item) {
          final eye = item['eye'] ?? '';
          final itemName = item['itemName'] ?? item['lens'] ?? 'Lens';
          return [
            itemName,
            eye,
            item['sph']?.toString() ?? '',
            item['cyl']?.toString() ?? '',
            item['axis']?.toString() ?? '',
            item['add']?.toString() ?? '',
            item['quantity']?.toString() ?? '1',
            item['salePrice']?.toString() ?? '',
          ];
        }).toList(),
      );
    }
    
    // Fallback if no items list but we have flat eye data (Retro-compatibility)
    // Check order['eye_r'] etc.
    final r = order['eye_r'] as Map?;
    final l = order['eye_l'] as Map?;
    final List<List<String>> rows = [];
    
    if (r != null && (r['sph'] != null || r['cyl'] != null)) {
       rows.add(['Right Lens', 'R', r['sph']?.toString()??'', r['cyl']?.toString()??'', r['axis']?.toString()??'', r['add']?.toString()??'', '1', '']);
    }
    if (l != null && (l['sph'] != null || l['cyl'] != null)) {
       rows.add(['Left Lens',  'L', l['sph']?.toString()??'', l['cyl']?.toString()??'', l['axis']?.toString()??'', l['add']?.toString()??'', '1', '']);
    }

    if (rows.isNotEmpty) {
       return pw.TableHelper.fromTextArray(
        headers: ['Item', 'Eye', 'Sph', 'Cyl', 'Axis', 'Add', 'Qty', 'Price'],
        headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        cellStyle: const pw.TextStyle(fontSize: 8),
        data: rows,
      );
    }

    return pw.Text('No items details available');
  }

  /// Generates and prints a Ledger Statement PDF
  static Future<void> printLedgerStatement(List<dynamic> transactions, {String? customerName, String? dateRange, double? closingBalance}) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
             pw.Center(child: pw.Text('Ledger Statement', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold))),
             pw.SizedBox(height: 10),
             if (customerName != null) pw.Text('Customer: $customerName', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
             if (dateRange != null) pw.Text('Period: $dateRange'),
             pw.SizedBox(height: 15),
             
             pw.TableHelper.fromTextArray(
               headers: ['Date', 'Particulars', 'Debit', 'Credit', 'Balance'],
               headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
               cellStyle: const pw.TextStyle(fontSize: 9),
               columnWidths: {
                 0: const pw.FixedColumnWidth(60), // Date
                 1: const pw.FlexColumnWidth(2), // Particulars
                 2: const pw.FixedColumnWidth(50), // Debit
                 3: const pw.FixedColumnWidth(50), // Credit
                 4: const pw.FixedColumnWidth(60), // Balance
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
               pw.SizedBox(height: 10),
               pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
                 pw.Text('Closing Balance: ${closingBalance.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
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
