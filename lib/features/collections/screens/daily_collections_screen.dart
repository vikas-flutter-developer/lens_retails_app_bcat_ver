import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/collection_service.dart';
import 'collection_breakdown_detail_screen.dart';

class DailyCollectionsScreen extends StatefulWidget {
  const DailyCollectionsScreen({super.key});

  @override
  State<DailyCollectionsScreen> createState() => _DailyCollectionsScreenState();
}

class _DailyCollectionsScreenState extends State<DailyCollectionsScreen> {
  final CollectionService _collectionService = CollectionService();
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  
  double _cash = 0;
  double _bank = 0;
  double _expenses = 0;
  Map<String, dynamic> _details = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final Map<String, dynamic> summary = await _collectionService.fetchDailySummary(_selectedDate);
      final double expenses = await _collectionService.fetchDailyExpenses(_selectedDate);
      
      setState(() {
        _cash = (summary['cash'] ?? 0.0).toDouble();
        _bank = (summary['bank'] ?? 0.0).toDouble();
        _details = Map<String, dynamic>.from(summary['details'] ?? {});
        _expenses = expenses;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ [DailyCollectionsScreen] Error loading: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    double netInHand = _cash - _expenses;
    String formattedDate = DateFormat('dd-MMMM-yyyy').format(_selectedDate);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text('Day Book & Cash Tracking'),
        actions: [
          IconButton(onPressed: _pickDate, icon: const Icon(Icons.calendar_month)),
          IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text('$formattedDate Summary', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 20),
            
            // Grand Total Card (Cash-in-Hand)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00B09B), Color(0xFF96C93D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))]
              ),
              child: Column(
                children: [
                  const Text('Net Cash in Hand', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 12),
                  Text('₹${netInHand.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Real-time reconciled balance', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Collections Breakdown
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  const ListTile(
                    title: Text('Collections Breakdown', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
                    leading: Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF1A237E)),
                  ),
                  const Divider(height: 1),
                  _buildRow('Total Cash Received', '₹${_cash.toStringAsFixed(2)}', Colors.green),
                  _buildRow('UPI / Bank / Card', '₹${_bank.toStringAsFixed(2)}', Colors.blue),
                  const Divider(height: 1),
                  _buildRow('Monthly Expenses Paid', '- ₹${_expenses.toStringAsFixed(2)}', Colors.red),
                  const SizedBox(height: 12),
                ],
              ),
            ),

            const SizedBox(height: 20),
            
            // Individual Bank Accounts (if any)
            if (_details.keys.any((k) => k != 'CASH'))
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    const ListTile(
                      title: Text('Account-wise Split', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                    ),
                    const Divider(height: 1),
                    ..._details.entries.where((e) => e.key != 'CASH').map((e) => 
                      _buildRow(e.key, '₹${e.value.toStringAsFixed(2)}', Colors.blueGrey)
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String amount, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 12),
              Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            ],
          ),
          Text(amount, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
