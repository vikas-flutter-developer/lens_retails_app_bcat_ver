import 'package:flutter/material.dart';

class CollectionBreakdownDetailScreen extends StatelessWidget {
  const CollectionBreakdownDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock Transaction Data
    final List<Map<String, dynamic>> transactions = [
      {'title': 'Eye Exam + Frame', 'mode': 'Cash', 'amount': 1500.0, 'time': '10:30 AM', 'color': Colors.green},
      {'title': 'Contact Lens Sale', 'mode': 'UPI', 'amount': 800.0, 'time': '11:15 AM', 'color': Colors.blue},
      {'title': 'RayBan Aviator', 'mode': 'Card', 'amount': 5500.0, 'time': '01:45 PM', 'color': Colors.orange},
      {'title': 'Repair & Service', 'mode': 'Cash', 'amount': 200.0, 'time': '02:30 PM', 'color': Colors.green},
      {'title': 'Insurance Claim Payout', 'mode': 'UPI', 'amount': 9700.0, 'time': '04:00 PM', 'color': Colors.blue},
      {'title': 'New Lens Fitting', 'mode': 'Card', 'amount': 1200.0, 'time': '04:45 PM', 'color': Colors.orange},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Breakdown'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final tx = transactions[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: tx['color'].withValues(alpha: 0.1),
                child: Icon(
                  tx['mode'] == 'Cash' ? Icons.money : 
                  tx['mode'] == 'UPI' ? Icons.qr_code : Icons.credit_card,
                  color: tx['color'],
                ),
              ),
              title: Text(tx['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(tx['mode'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    Text(tx['time'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              trailing: Text(
                '₹${tx['amount']}',
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.w900, 
                  color: Theme.of(context).colorScheme.primary
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
