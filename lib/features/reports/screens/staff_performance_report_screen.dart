import 'package:flutter/material.dart';
import '../services/report_service.dart';

class StaffPerformanceScreen extends StatefulWidget {
  final ReportService? reportService;
  const StaffPerformanceScreen({super.key, this.reportService});

  @override
  State<StaffPerformanceScreen> createState() => _StaffPerformanceScreenState();
}

class _StaffPerformanceScreenState extends State<StaffPerformanceScreen> {
  late final ReportService _reportService;
  bool _isLoading = true;
  List<Map<String, dynamic>> _performanceData = [];

  @override
  void initState() {
    super.initState();
    _reportService = widget.reportService ?? ReportService();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await _reportService.fetchStaffPerformance();
    setState(() {
      _performanceData = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: AppBar(
        title: const Text('Staff Performance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _performanceData.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _performanceData.length,
                    itemBuilder: (context, index) {
                      final staff = _performanceData[index];
                      return _buildPerformanceCard(staff);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'No performance data found',
            style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Ensure tasks are assigned to staff.'),
        ],
      ),
    );
  }

  Widget _buildPerformanceCard(Map<String, dynamic> staff) {
    final String name = staff['name'] ?? 'Unknown';
    final String role = staff['role'] ?? 'Staff';
    final int completed = staff['tasksCompleted'] ?? 0;
    final double sales = (staff['salesGenerated'] ?? 0).toDouble();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF1A237E),
                  radius: 24,
                  child: Text(name[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
                      ),
                      Text(
                        role,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A237E).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Active',
                        style: TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem('SALES GENERATED', '₹${sales.toStringAsFixed(0)}', Colors.green, Icons.payments_outlined),
                _buildStatItem('COMPLETED TASKS', '$completed', Colors.indigo, Icons.done_all),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 14),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey[600], letterSpacing: 0.8),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
