import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/report_service.dart';
import 'staff_performance_report_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ReportService _reportService = ReportService();
  DateTimeRange? _selectedDateRange;
  
  Map<String, dynamic>? _salesData;
  Map<String, dynamic>? _financialData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  Future<void> _fetchReport() async {
    setState(() => _isLoading = true);
    
    final fromStr = _selectedDateRange == null ? null : DateFormat('yyyy-MM-dd').format(_selectedDateRange!.start);
    final toStr = _selectedDateRange == null ? null : DateFormat('yyyy-MM-dd').format(_selectedDateRange!.end);

    try {
      final sales = await _reportService.fetchSalesReport(from: fromStr, to: toStr);
      final financial = await _reportService.fetchFinancialSummary(from: fromStr, to: toStr);

      setState(() {
        _salesData = sales;
        _financialData = financial?['data'];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading reports: $e');
      setState(() => _isLoading = false);
    }
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

  @override
  Widget build(BuildContext context) {
    // 1. Total Metrics
    final double totalRevenue = (_salesData?['revenue'] ?? 0).toDouble();
    final int totalTransactions = _salesData?['bookedOrders'] ?? 0;

    // 2. Dynamic Categories
    final List categories = _salesData?['salesCategoryAnalysis'] ?? [];
    
    // 3. Dynamic Payments
    final List payments = _salesData?['paymentModeSplit'] ?? [];
    
    // 4. Dynamic Job Status
    final List jobs = _salesData?['jobStatusMonitor'] ?? [];

    // 5. Dynamic Financials
    final double financialSales = (_financialData?['totalSales'] ?? 0).toDouble();
    final double financialExpenses = (_financialData?['totalExpenses'] ?? 0).toDouble();
    final double netProfit = (_financialData?['netProfit'] ?? 0).toDouble();
    final List expenseBreakdown = _financialData?['expenseBreakdown'] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: AppBar(
        title: const Text('Custom Analytics & Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload Reports',
            onPressed: _fetchReport,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchReport,
              child: ListView(
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
                          child: _buildStatCard(
                            'Total Sales', 
                            '₹${totalRevenue.toStringAsFixed(0)}', 
                            Colors.blue, 
                            Icons.payments_outlined
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            'Transactions', 
                            '$totalTransactions', 
                            Colors.green, 
                            Icons.receipt_long_outlined
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Business Intelligence Sections
                  if (categories.isNotEmpty)
                    _buildAnalysisSection('Sales Category Analysis', categories.map((item) {
                      final name = item['category'] ?? 'Other';
                      final double amount = (item['amount'] ?? 0).toDouble();
                      final double percent = (item['percentage'] ?? 0) / 100.0;
                      return _buildProgressRow(
                        name, 
                        percent, 
                        '₹${amount.toStringAsFixed(0)}', 
                        Colors.blue
                      );
                    }).toList()),

                  if (payments.isNotEmpty)
                    _buildAnalysisSection('Payment Mode Split', payments.map((item) {
                      final mode = item['mode'] ?? 'Unknown';
                      final double percent = (item['percentage'] ?? 0) / 100.0;
                      return _buildProgressRow(
                        mode, 
                        percent, 
                        '${(percent * 100).toStringAsFixed(0)}%', 
                        Colors.purple
                      );
                    }).toList()),

                  if (jobs.isNotEmpty)
                    _buildAnalysisSection('Job Status Monitor', jobs.map((item) {
                      final status = item['status'] ?? 'Unknown';
                      final int count = item['count'] ?? 0;
                      return _buildProgressRow(
                        status, 
                        0.5, 
                        '$count Jobs', 
                        Colors.amber
                      );
                    }).toList()),

                  // ----------------------------------------
                  // BRAND NEW PREMIUM FINANCIAL SUMMARY UI
                  // ----------------------------------------
                  _buildAnalysisSection('Financial & Profitability Summary', [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildFinancialMiniCard('REVENUE', '₹${financialSales.toStringAsFixed(0)}', Colors.green),
                        _buildFinancialMiniCard('EXPENSES', '₹${financialExpenses.toStringAsFixed(0)}', Colors.red),
                        _buildFinancialMiniCard('NET PROFIT', '₹${netProfit.toStringAsFixed(0)}', Colors.blue),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Expense Breakdown', 
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)
                    ),
                    const SizedBox(height: 12),
                    ...expenseBreakdown.map((item) {
                      final cat = item['category'] ?? 'General';
                      final double amount = (item['amount'] ?? 0).toDouble();
                      final double percent = financialExpenses > 0 ? (amount / financialExpenses) : 0.0;
                      return _buildProgressRow(
                        cat, 
                        percent, 
                        '₹${amount.toStringAsFixed(0)}', 
                        Colors.red
                      );
                    }),
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
                            BoxShadow(
                              color: const Color(0xFF1A237E).withOpacity(0.3), 
                              blurRadius: 10, 
                              offset: const Offset(0, 4)
                            ),
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
                                  Text('Task Completion & Sales Contribution Leaderboard', style: TextStyle(color: Colors.white70, fontSize: 13)),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03), 
            blurRadius: 10, 
            offset: const Offset(0, 4)
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A237E), letterSpacing: 0.5)),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildProgressRow(String label, double percent, String value, Color color) {
    return Padding(
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

  Widget _buildFinancialMiniCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey[600]),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
