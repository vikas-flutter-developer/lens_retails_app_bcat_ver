import 'dart:async';
import 'package:flutter/material.dart';
import '../services/ledger_service.dart';
import '../../auth/services/auth_service.dart';
import '../../../../core/services/print_service.dart';

class MyLedgerScreen extends StatefulWidget {
  const MyLedgerScreen({super.key});

  @override
  State<MyLedgerScreen> createState() => _MyLedgerScreenState();
}

class _MyLedgerScreenState extends State<MyLedgerScreen> {
  late final TextEditingController _fromDateController;
  late final TextEditingController _toDateController;

  final LedgerService _ledgerService = LedgerService();
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _refreshTimer;

  List<Map<String, dynamic>> _ledgerEntries = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _fromDateController = TextEditingController(
      text: "01-${now.month.toString().padLeft(2, '0')}-${now.year}"
    );
    _toDateController = TextEditingController(
      text: "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}"
    );
    _fetchLedger();
    
    // Auto-refresh every 30 seconds
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _fetchLedger(),
    );
  }

  String _formatDateForApi(String uiDate) {
    // uiDate is DD-MM-YYYY -> YYYY-MM-DD
    try {
      final parts = uiDate.split('-');
      if (parts.length == 3) {
        return '${parts[2]}-${parts[1]}-${parts[0]}';
      }
    } catch (_) {}
    return uiDate;
  }

  String _formatDisplayDate(String isoDate) {
    try {
      if (isoDate.isEmpty) return '';
      final dt = DateTime.parse(isoDate);
      return "${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}";
    } catch (e) {
      return isoDate;
    }
  }

  Future<void> _fetchLedger() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Debug logging
      debugPrint('🔍 [Ledger Screen] Start Date: ${_formatDateForApi(_fromDateController.text)}');
      debugPrint('🔍 [Ledger Screen] End Date: ${_formatDateForApi(_toDateController.text)}');
      
      final rawData = await _ledgerService.fetchLedger(
        startDate: _formatDateForApi(_fromDateController.text),
        endDate: _formatDateForApi(_toDateController.text),
      );
      
      debugPrint('🔍 [Ledger Screen] Received ${rawData.length} records');

      setState(() {
        int index = 1;
        _ledgerEntries = rawData.map((item) {
          return {
            'sn': (index++).toString(), 
            'date': _formatDisplayDate(item['date'] ?? ''),
            'type': item['transType'] ?? item['voucherType'] ?? item['type'] ?? 'Unknown',
            'vch': item['voucherNo'] ?? item['vchNo'] ?? '',
            'debit': item['debit']?.toString() ?? '0.00',
            'credit': item['credit']?.toString() ?? '0.00',
            'bal': item['balance']?.toString() ?? '0.00',
          };
        }).toList();

        if (_ledgerEntries.isEmpty) {
          _errorMessage = "No ledger records found for the selected date range.\n\nPossible reasons:\n• No transactions exist for your account\n• Try extending the date range\n• Contact support if you expect to see records";
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load ledger: $e";
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _fromDateController.dispose();
    _toDateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      controller.text =
          "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
    }
  }

  void _printLedger() async {
    try {
       final auth = AuthService();
       final name = await auth.getUserName();
       
       await PrintService.printLedgerStatement(
          _ledgerEntries,
          customerName: name,
          dateRange: "${_fromDateController.text} to ${_toDateController.text}",
       );
    } catch (e) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Print Error: $e'), backgroundColor: Colors.red));
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalDebit = 0;
    double totalCredit = 0;
    for (var entry in _ledgerEntries) {
      totalDebit += double.tryParse(entry['debit']?.replaceAll(',', '') ?? '0') ?? 0.0;
      totalCredit += double.tryParse(entry['credit']?.replaceAll(',', '') ?? '0') ?? 0.0;
    }
    double netBalance = totalCredit - totalDebit;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        title: const Text('My Ledger Statement', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A237E),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _printLedger,
            icon: const Icon(Icons.print, color: Colors.white),
            tooltip: 'Print Statement',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchLedger,
        color: const Color(0xFF1A237E),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Running Balance Summary Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1A237E).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text('Total Net Balance', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Text('₹${netBalance.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryColumn('Total Credit (In)', '₹${totalCredit.toStringAsFixed(2)}', Colors.greenAccent),
                        Container(width: 1, height: 30, color: Colors.white30),
                        _buildSummaryColumn('Total Debit (Out)', '₹${totalDebit.toStringAsFixed(2)}', Colors.redAccent),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Date Filters
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE2E8F0))),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildDateInput('From Date', _fromDateController)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildDateInput('To Date', _toDateController)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A237E),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          onPressed: _fetchLedger,
                          icon: const Icon(Icons.search, size: 18),
                          label: const Text('Filter Statement', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Transactions Header
              const Text('Transaction Records', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
              const SizedBox(height: 12),

              // Loading / Error / Empty States
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator(color: Color(0xFF1A237E))),
                )
              else if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Center(child: Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 14))),
                )
              else if (_ledgerEntries.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: Text('No ledger entries found.', style: TextStyle(color: Colors.grey, fontSize: 14))),
                )
              else
                // Beautiful Transaction List
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _ledgerEntries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final e = _ledgerEntries[index];
                    final isExpense = e['type']?.toString().toLowerCase() == 'expense' || (double.tryParse(e['debit']?.toString() ?? '0') ?? 0) > 0;
                    final amt = isExpense ? '- ₹${double.tryParse(e['debit']?.toString() ?? '0')?.toStringAsFixed(2) ?? e['debit']}' : '+ ₹${double.tryParse(e['credit']?.toString() ?? '0')?.toStringAsFixed(2) ?? e['credit']}';

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE2E8F0))),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            // Beautiful Transaction circular icon
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isExpense ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                                color: isExpense ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isExpense ? 'Store Expense' : (e['sn']?.toString() == 'CASH-IN' ? 'Cash Collection' : 'UPI/Bank/Card Collection'),
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${e['date']} • Vch: ${e['vch']}',
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                                  ),
                                ],
                              ),
                            ),

                            // Amount & Balance
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  amt,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: isExpense ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Bal: ₹${double.tryParse(e['bal']?.toString() ?? '0')?.toStringAsFixed(2) ?? e['bal']}',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4B5563)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryColumn(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: valueColor, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildDateInput(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF1A237E),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          readOnly: true,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            prefixIcon: const Icon(Icons.calendar_month, size: 18, color: Color(0xFF1A237E)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1A237E)),
            ),
          ),
          onTap: () => _selectDate(context, controller),
        ),
      ],
    );
  }
}
