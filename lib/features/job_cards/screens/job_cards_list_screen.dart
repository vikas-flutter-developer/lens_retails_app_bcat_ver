import 'package:flutter/material.dart';
import '../../orders/services/order_service.dart';
import '../../orders/screens/add_order_screen.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/config/app_config.dart';

class JobCardsListScreen extends StatefulWidget {
  const JobCardsListScreen({super.key});

  @override
  State<JobCardsListScreen> createState() => _JobCardsListScreenState();
}

class _JobCardsListScreenState extends State<JobCardsListScreen> {
  final OrderService _orderService = OrderService();
  List<Map<String, dynamic>> _jobCards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchJobCards();
  }

  Future<void> _fetchJobCards() async {
    setState(() => _isLoading = true);
    try {
      final orders = await _orderService.fetchOrders();
      // Filter for RX orders specifically for Job Cards
      setState(() {
        _jobCards = orders.where((o) => o['type'] == 'RX').toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading job cards: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _updateStatus(Map<String, dynamic> jobCard, String newStatus) async {
    try {
      // Balance collection is now handled inside OrderService.updateOrderStatus
      // for better persistence in Mock Mode.

      try {
        await _orderService.updateOrderStatus(
          jobCard['id'],
          'RX',
          newStatus,
          items: jobCard['items'],
        );
      } catch (e) {
        // If in Mock Mode, we ignore the API error and proceed with the local/mock update
        if (!AppConfig.useMockData) rethrow;
        debugPrint('⚠️ [JobCard] API failed but proceeding with Mock update: $e');
      }

      await _fetchJobCards(); // Refresh list FIRST so UI updates immediately
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppConfig.useMockData ? 'Mock Status updated to $newStatus' : 'Status updated to $newStatus'), 
            backgroundColor: Colors.green
          ),
        );
      }

      // THEN launch WhatsApp
      _launchWhatsApp(jobCard, newStatus);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _collectManualBalance(Map<String, dynamic> jobCard) async {
    final double balance = double.tryParse(jobCard['dueAmount']?.toString() ?? '0') ?? 0.0;
    if (balance <= 0) return;

    try {
      if (AppConfig.useMockData) {
        // Manually update MockData for persistence
        final index = MockData.mockOrders.indexWhere((o) => o['id'] == jobCard['id']);
        if (index != -1) {
          final order = MockData.mockOrders[index];
          MockData.addSale(balance, mode: 'Cash');
          final double totalPaid = (double.tryParse(order['paidAmount']?.toString() ?? '0') ?? 0.0) + balance;
          order['paidAmount'] = totalPaid.toString();
          order['dueAmount'] = "0.0";
        }
      }

      await _fetchJobCards(); // Refresh UI
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Balance of ₹$balance collected!'), backgroundColor: Colors.orange[800]),
        );
      }

      // Launch WhatsApp with Payment Confirmation
      _launchWhatsApp(jobCard, 'PaymentReceived');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to collect balance: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _launchWhatsApp(Map<String, dynamic> jobCard, String status) async {
    final String name = jobCard['customer'] ?? 'Customer';
    final String mobile = jobCard['mobile'] ?? '';
    final String id = jobCard['sn'] ?? '';
    
    if (mobile.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer mobile number not found')),
        );
      }
      return;
    }

    String message = "";
    if (status == 'In Progress') {
      message = "Hello $name,\n\nYour optical order (Job Code: $id) is now IN PROGRESS! 🛠️✨\n\nYour lenses are being carefully processed by our lab. We will notify you as soon as they are ready for collection.\n\nThank you for your patience! 👓";
    } else if (status == 'Ready') {
      message = "Hello $name,\n\nYour optical order (Job Code: $id) is now READY for collection! 👓✨\n\nPlease visit our store to collect your glasses.\n\nThank you for choosing Lens Retail!";
    } else if (status == 'Delivered') {
      final double total = double.tryParse(jobCard['amount']?.toString() ?? '0') ?? 0.0;
      message = "Hello $name,\n\nYour optical order (Job Code: $id) has been DELIVERED! ✅\n\nTotal Amount: ₹${total.toStringAsFixed(0)}\nStatus: Fully Paid\n\nThank you for your business! We hope you love your new glasses! 👓✨";
    } else if (status == 'PaymentReceived') {
      final double total = double.tryParse(jobCard['amount']?.toString() ?? '0') ?? 0.0;
      message = "Hello $name,\n\nWe have received your BALANCE PAYMENT for order $id. ✅\n\nTotal Amount: ₹${total.toStringAsFixed(0)}\nStatus: Fully Paid\n\nThank you for your payment! Your order is still being processed as per the schedule. 👓✨";
    } else if (status == 'BalanceReminder') {
      final String balance = jobCard['dueAmount']?.toString() ?? '0';
      message = "Hello $name,\n\nThis is a friendly reminder regarding your optical order $id. 👓\n\nA balance payment of ₹$balance is pending. You can pay this at the time of collection.\n\nThank you, Lens Retail!";
    } else if (status == 'Cancelled') {
      message = "Hello $name,\n\nYour optical order (Job Code: $id) has been CANCELLED. ❌\n\nIf you have any questions or would like to re-order, please contact our store.\n\nThank you, Lens Retail.";
    } else {
      // Fallback for any other status
      message = "Hello $name, Your optical order (Job Code: $id) status has been updated to: $status. Thank you, Lens Retail.";
    }
    
    // Format mobile: remove non-digits and ensure it has 91 prefix if needed
    String cleanMobile = mobile.replaceAll(RegExp(r'\D'), '');
    if (cleanMobile.length == 10) cleanMobile = "91$cleanMobile";

    final Uri url = Uri.parse("https://wa.me/$cleanMobile?text=${Uri.encodeComponent(message)}");

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch WhatsApp';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening WhatsApp: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Retail Job Cards'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchJobCards,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New Job Card',
            onPressed: () async {
              final result = await Navigator.pushNamed(context, '/add_order');
              if (result == true) _fetchJobCards();
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _jobCards.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.assignment_late_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('No Job Cards found', style: TextStyle(fontSize: 18, color: Colors.grey)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {
                          final result = await Navigator.pushNamed(context, '/add_order');
                          if (result == true) _fetchJobCards();
                        },
                        child: const Text('Create Your First Job Card'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _jobCards.length,
                  itemBuilder: (context, index) {
                    final jobCard = _jobCards[index];
                    return _buildJobCard(context, jobCard);
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/add_order');
          if (result == true) _fetchJobCards();
        },
        icon: const Icon(Icons.add),
        label: const Text('New Job Card'),
      ),
    );
  }

  Widget _buildJobCard(BuildContext context, Map<String, dynamic> jobCard) {
    final String status = jobCard['status'] ?? 'Pending';
    final String name = jobCard['customer'] ?? 'Unknown Customer';
    final String id = jobCard['sn'] ?? 'N/A';
    final String date = jobCard['date'] ?? 'N/A';
    final double total = double.tryParse(jobCard['amount']?.toString() ?? '0') ?? 0.0;
    final double currentDue = double.tryParse(jobCard['dueAmount']?.toString() ?? '0') ?? 0.0;

    Color statusColor;
    switch (status) {
      case 'Pending':
        statusColor = Colors.orange;
        break;
      case 'In Progress':
        statusColor = Colors.blue;
        break;
      case 'Ready':
        statusColor = Colors.teal;
        break;
      case 'Done':
        statusColor = Colors.teal;
        break;
      case 'Delivered':
        statusColor = Colors.green;
        break;
      case 'Cancelled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(16),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(name, 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _buildStatusBadge(status, statusColor),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('Job Code: $id | Date: $date'),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total: ₹${total.toStringAsFixed(2)}', 
                  style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                if (status != 'Delivered')
                  Text(
                    'Balance: ₹${currentDue.toStringAsFixed(0)}',
                    style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold, fontSize: 12),
                  ),
              ],
            ),
          ],
        ),
        children: [
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Update Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _statusButton(jobCard, 'In Progress', Colors.blue),
                    _statusButton(jobCard, 'Ready', Colors.teal),
                    _statusButton(jobCard, 'Delivered', Colors.green),
                    _statusButton(jobCard, 'Cancelled', Colors.red),
                  ],
                ),
                if (currentDue > 0 && status != 'Delivered') ...[
                  const SizedBox(height: 16),
                   const Text('Payments:', style: TextStyle(fontWeight: FontWeight.bold)),
                   const SizedBox(height: 8),
                   Row(
                     children: [
                       Expanded(
                         child: ElevatedButton.icon(
                           onPressed: () => _launchWhatsApp(jobCard, 'BalanceReminder'),
                           icon: const Icon(Icons.notifications_active_outlined),
                           label: const Text('Reminder', style: TextStyle(fontSize: 12)),
                           style: ElevatedButton.styleFrom(
                             backgroundColor: Colors.blueGrey,
                             foregroundColor: Colors.white,
                             padding: const EdgeInsets.symmetric(vertical: 12),
                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                           ),
                         ),
                       ),
                       const SizedBox(width: 8),
                       Expanded(
                         child: ElevatedButton.icon(
                           onPressed: () => _collectManualBalance(jobCard),
                           icon: const Icon(Icons.payments_outlined),
                           label: const Text('Collect', style: TextStyle(fontSize: 12)),
                           style: ElevatedButton.styleFrom(
                             backgroundColor: Colors.orange[800],
                             foregroundColor: Colors.white,
                             padding: const EdgeInsets.symmetric(vertical: 12),
                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                           ),
                         ),
                       ),
                     ],
                   ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(status, 
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _statusButton(Map<String, dynamic> jobCard, String status, Color color) {
    final bool isCurrent = jobCard['status'] == status;
    return ActionChip(
      label: Text(status, style: TextStyle(color: isCurrent ? Colors.white : color)),
      backgroundColor: isCurrent ? color : color.withOpacity(0.1),
      onPressed: isCurrent ? null : () => _updateStatus(jobCard, status),
    );
  }
}

