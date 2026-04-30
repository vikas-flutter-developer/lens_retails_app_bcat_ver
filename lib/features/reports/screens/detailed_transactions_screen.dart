import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/pdf_report_util.dart';

class DetailedTransactionsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  final String title;

  const DetailedTransactionsScreen({
    super.key, 
    required this.transactions,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => PdfReportUtil.generateSalesReport(transactions),
          )
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: transactions.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          final sale = transactions[index];
          final date = DateTime.parse(sale['date']);
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            leading: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.receipt_long, color: Color(0xFF1A237E)),
                Text(sale['id'], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
            title: Text(DateFormat('dd MMMM yyyy').format(date), style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(DateFormat('hh:mm a').format(date), style: const TextStyle(color: Colors.grey)),
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('₹${sale['amount']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                const Text('Paid', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            onTap: () => PdfReportUtil.generateInvoice(sale),
          );
        },
      ),
    );
  }
}
