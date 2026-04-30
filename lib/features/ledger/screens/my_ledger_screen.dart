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
  final _fromDateController = TextEditingController(text: '01-01-2026');

  final _toDateController = TextEditingController(text: '13-01-2026');

  final LedgerService _ledgerService = LedgerService();
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _refreshTimer;

  List<Map<String, dynamic>> _ledgerEntries = [];

  @override
  void initState() {
    super.initState();
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
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('My Ledger', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1A237E),
        centerTitle: true,
        actions: [

        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchLedger,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(), // Important for RefreshIndicator
          padding: const EdgeInsets.all(16.0),
          child: Column(
          children: [
            // Filter Bar
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth > 800) {
                          return _buildDesktopFilterRow();
                        } else {
                          return _buildMobileFilterColumn();
                        }
                      },
                    ),
                    const Divider(height: 32),
                    // Ledger Table
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: _buildLedgerTable(),
                    ),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(),
                      ),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    if (!_isLoading &&
                        _ledgerEntries.isEmpty &&
                        _errorMessage == null)
                      const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text(
                          'No records found',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
   );
  }

  Widget _buildLedgerTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      width: 800, // Safe minimum width to ensure no overflow
      child: Table(
        columnWidths: const {
          0: FixedColumnWidth(40),  // SN
          1: FixedColumnWidth(90),  // Date
          2: FixedColumnWidth(100), // Type
          3: FixedColumnWidth(130), // Vch
          4: FixedColumnWidth(90),  // Debit
          5: FixedColumnWidth(90),  // Credit
          6: FixedColumnWidth(100), // Balance
        },
        children: [
          // Header Row
          TableRow(
            decoration: const BoxDecoration(color: Colors.white),
            children: const [
              _TableHeaderCell('SN'),
              _TableHeaderCell('Date'),
              _TableHeaderCell('Trans Type'),
              _TableHeaderCell('Vch/Bill No'),
              _TableHeaderCell('Debit'),
              _TableHeaderCell('Credit'),
              _TableHeaderCell('Balance'),
            ],
          ),
          // Data Rows
          if (!_isLoading) ..._ledgerEntries.map((e) {
            return TableRow(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              children: [
                _TableCell(e['sn'] ?? ''),
                _TableCell(e['date'] ?? ''),
                _TableCell(e['type'] ?? ''),
                _TableCell(e['vch'] ?? ''),
                _TableCell(e['debit'] ?? ''),
                _TableCell(e['credit'] ?? ''),
                _TableCell(
                  e['bal'] ?? '',
                  isBold: true,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDesktopFilterRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(
          width: 150,
          child: _buildDateInput('From Date', _fromDateController),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 150,
          child: _buildDateInput('To Date', _toDateController),
        ),
        const SizedBox(width: 16),
        SizedBox(
          height: 48,
          width: 120,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            onPressed: _fetchLedger,
            child: const Text('Search'),
          ),
        ),
        const SizedBox(width: 16),
        IconButton(
          onPressed: _printLedger,
          icon: const Icon(Icons.print, color: Colors.blueGrey, size: 30),
        ),
      ],
    );
  }

  Widget _buildMobileFilterColumn() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildDateInput('From Date', _fromDateController)),
            const SizedBox(width: 12),
            Expanded(child: _buildDateInput('To Date', _toDateController)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                onPressed: _fetchLedger,
                child: const Text('Search'),
              ),
            ),
            const SizedBox(width: 16),
            IconButton(
              onPressed: _printLedger,
              icon: const Icon(Icons.print, color: Colors.blueGrey, size: 30),
            ),
          ],
        ),
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
            color: Colors.teal,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          readOnly: true,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            filled: true,
            fillColor: Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Colors.grey),
            ),
          ),
          onTap: () => _selectDate(context, controller),
        ),
      ],
    );
  }
}

class _TableHeaderCell extends StatelessWidget {
  final String label;

  const _TableHeaderCell(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  final String value;
  final bool isBold;

  const _TableCell(this.value, {this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
      child: Text(
        value,
        style: TextStyle(
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
