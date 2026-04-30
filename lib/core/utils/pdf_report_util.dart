import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PdfReportUtil {
  static Future<void> generateSalesReport(List<Map<String, dynamic>> data, {DateTimeRange? range}) async {
    final pdf = pw.Document();
    final dateStr = range == null 
        ? 'All Time' 
        : '${DateFormat('dd MMM yyyy').format(range.start)} - ${DateFormat('dd MMM yyyy').format(range.end)}';

    double total = data.fold(0.0, (sum, item) => sum + (item['amount'] ?? 0));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Sales Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.Text('Date: ${DateFormat('dd MMM yyyy').format(DateTime.now())}'),
              ],
            ),
          ),
          pw.Text('Report Period: $dateStr'),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: ['Invoice ID', 'Date', 'Amount (INR)'],
            data: data.map((item) {
              final d = DateTime.parse(item['date']);
              return [
                item['id'],
                DateFormat('dd MMM yyyy, hh:mm a').format(d),
                '${item['amount']}'
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text('Total Revenue: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('INR ${total.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  static Future<void> generateInvoice(Map<String, dynamic> sale) async {
    final pdf = pw.Document();
    final date = DateTime.parse(sale['date']);

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Padding(
          padding: const pw.EdgeInsets.all(40),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                   pw.Text('INVOICE', style: pw.TextStyle(fontSize: 30, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                   pw.Text('Lens App Retail'),
                ],
              ),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 20),
              pw.Text('Invoice ID: ${sale['id']}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('Date: ${DateFormat('dd MMM yyyy, hh:mm a').format(date)}'),
              pw.SizedBox(height: 40),
              pw.TableHelper.fromTextArray(
                context: context,
                headers: ['Description', 'Qty', 'Unit Price', 'Total'],
                data: [
                  ['Optical Item Service / Sale', '1', '${sale['amount']}', '${sale['amount']}'],
                ],
              ),
              pw.SizedBox(height: 40),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Subtotal: ${sale['amount']}'),
                      pw.Text('Tax (0%): 0.00'),
                      pw.Divider(),
                      pw.Text('Grand Total: INR ${sale['amount']}', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                    ],
                  )
                ],
              ),
              pw.Spacer(),
              pw.Center(child: pw.Text('Thank you for your business!', style: pw.TextStyle(fontStyle: pw.FontStyle.italic))),
            ],
          ),
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save(), name: 'Invoice_${sale['id']}.pdf');
  }
}
