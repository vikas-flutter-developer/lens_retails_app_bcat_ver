import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/services/retail_mock_api.dart';
import '../../../core/utils/pdf_report_util.dart';
import '../../../core/mock/mock_data.dart';
import 'detailed_transactions_screen.dart';
import 'staff_performance_report_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final RetailMockApi _api = RetailMockApi();
  DateTimeRange? _selectedDateRange;
  List<Map<String, dynamic>> _reportData = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchReport(); // Load all by default
  }

  Future<void> _fetchReport() async {
    setState(() => _isLoading = true);
    try {
      final data = await _api.fetchSales(
        start: _selectedDateRange?.start,
        end: _selectedDateRange?.end,
      );
      setState(() {
        _reportData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showCategoryDetails(String category, String total) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$category Breakdown', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
            const SizedBox(height: 8),
            Text('Total Contribution: $total', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            const Divider(height: 32),
            ..._reportData.take(2).map((sale) => ListTile(
              leading: const Icon(Icons.receipt_outlined),
              title: Text('Order #${sale['id']}'),
              subtitle: Text('Items: ${category == 'Lenses' ? 'Crizal Sapphire' : 'Ray-Ban Frame'}'),
              trailing: const Icon(Icons.picture_as_pdf_outlined, color: Colors.red, size: 20),
              onTap: () {
                PdfReportUtil.generateInvoice(sale);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invoice #${sale['id']} Generated')));
              },
            )),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E), 
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text('CLOSE'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
      _fetchReport();
    }
  }

  void _showJobStatusDetails(String status, String count) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.precision_manufacturing_outlined, color: Color(0xFF1A237E), size: 24),
                const SizedBox(width: 12),
                Text('Jobs: $status', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
              ],
            ),
            const SizedBox(height: 8),
            Text('Currently tracking $count items in this stage', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            const Divider(height: 32),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: int.tryParse(count.split(' ')[0]) ?? 2,
                itemBuilder: (context, index) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(backgroundColor: Colors.blue[50], child: Text('${index + 1}', style: const TextStyle(fontSize: 12))),
                  title: Text('Job Card: #JC-${1000 + index}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text('Customer: ${[ "Vikas Sharma", "Amit Patel", "Rahul Gupta", "Sonia Jain", "Priya Singh", "Karan Malhotra" ][index % 6]}', style: const TextStyle(fontSize: 12)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: (index % 3 == 0) ? Colors.orange[50] : Colors.blue[50], borderRadius: BorderRadius.circular(8)),
                    child: Text((index % 3 == 0) ? 'Urgent' : 'Normal', style: TextStyle(color: (index % 3 == 0) ? Colors.orange[900] : Colors.blue[900], fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E), 
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text('CLOSE MONITOR'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalRevenue = MockData.totalRevenue;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Analytics & Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export PDF Report',
            onPressed: () {
              if (_reportData.isNotEmpty) {
                PdfReportUtil.generateSalesReport(_reportData, range: _selectedDateRange);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF Report Generated Successfully')));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No data to export')));
              }
            },
          )
        ],
      ),
      body: ListView(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDateRange == null
                        ? 'Showing: All Time'
                        : 'Filter: ${DateFormat('dd MMM yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM yyyy').format(_selectedDateRange!.end)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _pickDateRange,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.date_range, size: 18),
                  label: const Text('Filter Dates'),
                )
              ],
            ),
          ),
          
          // Summary Cards
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) => DetailedTransactionsScreen(
                          transactions: _reportData, 
                          title: 'Sales Details'
                        ))
                      );
                    },
                    child: _buildStatCard('Total Sales', '₹${totalRevenue.toStringAsFixed(0)}', Colors.blue, Icons.payments_outlined),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) => DetailedTransactionsScreen(
                          transactions: _reportData, 
                          title: 'Transaction History'
                        ))
                      );
                    },
                    child: _buildStatCard('Transactions', '${_reportData.length}', Colors.green, Icons.receipt_long_outlined),
                  ),
                ),
              ],
            ),
          ),

          // Business Intelligence Sections
          _buildAnalysisSection('Sales Category Analysis', [
            _buildProgressRow('Lenses', 0.65, '₹${(totalRevenue * 0.65).toStringAsFixed(0)}', Colors.blue, () => _showCategoryDetails('Lenses', '₹${(totalRevenue * 0.65).toStringAsFixed(0)}')),
            _buildProgressRow('Frames', 0.25, '₹${(totalRevenue * 0.25).toStringAsFixed(0)}', Colors.indigo, () => _showCategoryDetails('Frames', '₹${(totalRevenue * 0.25).toStringAsFixed(0)}')),
            _buildProgressRow('Accessories', 0.10, '₹${(totalRevenue * 0.10).toStringAsFixed(0)}', Colors.teal, () => _showCategoryDetails('Accessories', '₹${(totalRevenue * 0.10).toStringAsFixed(0)}')),
          ]),

          _buildAnalysisSection('Payment Mode Split', [
            _buildProgressRow('Cash', 0.40, '40%', Colors.orange, () {}),
            _buildProgressRow('UPI / GPay', 0.50, '50%', Colors.purple, () {}),
            _buildProgressRow('Credit Card', 0.10, '10%', Colors.red, () {}),
          ]),

          _buildAnalysisSection('Job Status Monitor', [
            _buildProgressRow('In Lab', 0.30, '4 Jobs', Colors.blue, () => _showJobStatusDetails('In Lab', '4 Jobs')),
            _buildProgressRow('Fitting', 0.50, '6 Jobs', Colors.amber, () => _showJobStatusDetails('Fitting', '6 Jobs')),
            _buildProgressRow('Ready to Pickup', 0.20, '2 Jobs', Colors.green, () => _showJobStatusDetails('Ready to Pickup', '2 Jobs')),
          ]),
          
          // Staff Performance Link
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => const StaffPerformanceScreen())
                );
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF1A237E).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.query_stats_rounded, color: Colors.white, size: 32),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Staff Performance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                          Text('Task Completion vs Pending Analysis', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                  ],
                ),
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.fromLTRB(20, 32, 20, 16),
            child: Text('RECENT TRANSACTIONS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.grey, letterSpacing: 1.2)),
          ),

          // Transaction List
          _isLoading 
            ? const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
            : _reportData.isEmpty
                ? const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No data found for this range')))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _reportData.length,
                    itemBuilder: (context, index) {
                      final sale = _reportData[index];
                      final date = DateTime.parse(sale['date']);
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                        color: Colors.white,
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.receipt_outlined, color: Color(0xFF1A237E)),
                          ),
                          title: Text('Invoice: ${sale['id']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(DateFormat('dd MMM yyyy, hh:mm a').format(date), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          trailing: const Icon(Icons.download_rounded, color: Color(0xFF1A237E)),
                          onTap: () => PdfReportUtil.generateInvoice(sale),
                        ),
                      );
                    },
                  ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildAnalysisSection(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF1A237E), letterSpacing: 0.5)),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildProgressRow(String label, double percent, String value, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E293B))),
                Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: color)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: percent,
                backgroundColor: color.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(color: color.withOpacity(0.7), fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
}
