import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/master_data_service.dart';
import '../../../core/mock/mock_data.dart';
import 'vendor_order_form_screen.dart';

class VendorDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> vendor;
  final Function() onUpdate;

  const VendorDetailsScreen({
    super.key, 
    required this.vendor, 
    required this.onUpdate
  });

  @override
  State<VendorDetailsScreen> createState() => _VendorDetailsScreenState();
}

class _VendorDetailsScreenState extends State<VendorDetailsScreen> {
  final MasterDataService _masterDataService = MasterDataService();
  Map<String, dynamic>? _detailedVendor;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVendorDetails();
  }

  Future<void> _loadVendorDetails() async {
    setState(() => _isLoading = true);
    final String id = widget.vendor['id']?.toString() ?? '';
    
    try {
      final details = await _masterDataService.fetchVendorById(id);
      setState(() {
        _detailedVendor = details;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading vendor details: $e');
      setState(() => _isLoading = false);
    }
  }

  void _launchWhatsApp(String phone) async {
    final String vendorName = (_detailedVendor?['name'] ?? widget.vendor['name'] ?? 'Vendor').toString();
    final items = MockData.mockInventory.where((i) => (i['vendorName'] ?? i['vendor']) == vendorName).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VendorOrderFormScreen(
          vendor: _detailedVendor ?? widget.vendor,
          initialItems: items.map((e) => Map<String, dynamic>.from(e)).toList(),
        ),
      ),
    );
  }

  void _launchCall(String phone) async {
    final url = "tel:$phone";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  // Beautiful bottom sheet for Total Orders
  void _showOrdersSheet(BuildContext context, String vendorName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.shopping_bag_outlined, color: Colors.blue),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$vendorName Orders', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const Text('History of purchase orders booked', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _orderItem('PO-2026-9812', 'May 05, 2026', '₹45,500', 'Delivered', Colors.green),
                  _orderItem('PO-2026-9743', 'Apr 28, 2026', '₹18,000', 'In Transit', Colors.orange),
                  _orderItem('PO-2026-9629', 'Apr 14, 2026', '₹12,450', 'Delivered', Colors.green),
                  _orderItem('PO-2026-9410', 'Mar 30, 2026', '₹8,900', 'Cancelled', Colors.red),
                  _orderItem('PO-2026-9218', 'Mar 15, 2026', '₹14,200', 'Delivered', Colors.green),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _orderItem(String poNumber, String date, String amount, String status, Color statusColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(poNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              Text(date, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          Row(
            children: [
              Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A237E))),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status, 
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Beautiful bottom sheet for Outstanding Balance breakdown
  // Beautiful bottom sheet for Outstanding Balance breakdown loaded dynamically from the live API
  void _showOutstandingSheet(BuildContext context, String vendorName, double outstandingAmount) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return FutureBuilder<Map<String, dynamic>?>(
            future: _masterDataService.fetchVendorLedger(widget.vendor['id']?.toString() ?? ''),
            builder: (context, snapshot) {
              final bool isSheetLoading = snapshot.connectionState == ConnectionState.waiting;
              final data = snapshot.data;
              final List<dynamic> transactions = data != null ? (data['transactions'] ?? []) : [];

              return Container(
                height: MediaQuery.of(ctx).size.height * 0.75,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.account_balance_wallet_outlined, color: Colors.red),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('$vendorName Ledger Statement', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                                Text(
                                  isSheetLoading 
                                      ? 'Loading ledger...' 
                                      : 'Statement • Outstanding: ₹${(data != null ? data['outstandingBalance'] ?? outstandingAmount : outstandingAmount).toString()}', 
                                  style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                    Expanded(
                      child: isSheetLoading
                          ? const Center(child: CircularProgressIndicator())
                          : transactions.isEmpty
                              ? const Center(child: Text('No transactions found in ledger.'))
                              : ListView.builder(
                                  padding: const EdgeInsets.all(20),
                                  itemCount: transactions.length,
                                  itemBuilder: (context, index) {
                                    final tx = transactions[index];
                                    final double debit = (tx['debit'] ?? 0).toDouble();
                                    final double credit = (tx['credit'] ?? 0).toDouble();
                                    final double balance = (tx['balance'] ?? 0).toDouble();
                                    
                                    final bool isPayment = tx['voucherType'] == 'Payment';
                                    
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: Colors.grey.shade100),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(tx['particulars'] ?? 'Transaction', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                                const SizedBox(height: 4),
                                                Text('${tx['date']} • Type: ${tx['voucherType']}', style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                                                if (tx['voucherNo'] != '-')
                                                  Text('Ref: ${tx['voucherNo']}', style: const TextStyle(color: Colors.black54, fontSize: 10)),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                isPayment ? 'Dr ₹${debit.toStringAsFixed(0)}' : 'Cr ₹${credit.toStringAsFixed(0)}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: isPayment ? Colors.green : Colors.red,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Bal: ₹${balance.toStringAsFixed(0)}',
                                                style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              );
            },
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> v = _detailedVendor ?? widget.vendor;

    final String name = (v['name'] ?? v['Name'] ?? 'Unnamed').toString();
    final String phone = v['phone'] ?? v['MobileNumber'] ?? '9876543210';
    final String email = v['email'] ?? v['Email'] ?? 'contact@lab.com';
    
    final int totalOrders = v['totalOrders'] ?? 24;
    final double outstanding = (v['outstanding'] ?? 12450.0).toDouble();
    
    final String contactPerson = v['contactPerson'] ?? 'Admin Manager';
    final String address = v['address'] ?? v['Address'] ?? 'Not set';
    final String dob = v['dob'] ?? '15-May-1985';
    final String gstin = v['gstin'] ?? '09AAACB1234F1Z1';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Vendor Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            tooltip: 'Edit Profile',
            onPressed: () => _showEditVendorSheet(context, v),
          ),
          IconButton(
            icon: const Icon(Icons.refresh), 
            tooltip: 'Reload Profile',
            onPressed: _loadVendorDetails,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(name, email, phone),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMetricsRow(context, name, totalOrders, outstanding),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('BUSINESS INFORMATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF1A237E),
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () => _showEditVendorSheet(context, v),
                              icon: const Icon(Icons.edit, size: 14),
                              label: const Text('Edit Info', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildInfoCard(contactPerson, address, dob, gstin),
                        const SizedBox(height: 30),
                        const Text('SUPPLIED ITEMS & PRICING', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                        const SizedBox(height: 12),
                        _buildVendorItems(name),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomActions(context, name, outstanding),
    );
  }

  Widget _buildHeader(String name, String email, String phone) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      decoration: const BoxDecoration(
        color: Color(0xFF1A237E),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 35,
                backgroundColor: Colors.white24,
                child: Text(name.isNotEmpty ? name[0] : 'V', style: const TextStyle(fontSize: 30, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text(email, style: const TextStyle(color: Colors.white70)),
                    Text('Phone: $phone', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _contactButton(Icons.phone_outlined, 'Call', Colors.green, () => _launchCall(phone)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _contactButton(Icons.message_outlined, 'WhatsApp', Colors.blue, () => _launchWhatsApp(phone)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _contactButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: color,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildMetricsRow(BuildContext ctx, String name, int totalOrders, double outstanding) {
    return Row(
      children: [
        _metricBox(
          'Total Orders', 
          '$totalOrders', 
          Icons.shopping_bag_outlined, 
          Colors.blue,
          onTap: () => _showOrdersSheet(ctx, name),
        ),
        const SizedBox(width: 12),
        _metricBox(
          'Outstanding', 
          '₹${outstanding.toStringAsFixed(0)}', 
          Icons.account_balance_wallet_outlined, 
          Colors.red,
          onTap: () => _showOutstandingSheet(ctx, name, outstanding),
        ),
      ],
    );
  }

  Widget _metricBox(String label, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, size: 20, color: color),
                  Icon(Icons.arrow_outward, size: 14, color: color.withOpacity(0.5)),
                ],
              ),
              const SizedBox(height: 12),
              Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String contactPerson, String address, String dob, String gstin) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _infoRow(Icons.person_outline, 'Contact Person', contactPerson),
          const Divider(height: 24),
          _infoRow(Icons.location_on_outlined, 'Address', address),
          const Divider(height: 24),
          _infoRow(Icons.calendar_today_outlined, 'DOB / Incorporation Date', dob),
          const Divider(height: 24),
          _infoRow(Icons.receipt_long_outlined, 'GSTIN', gstin),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF1A237E)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVendorItems(String vendorName) {
    final items = MockData.mockInventory.where((i) => (i['vendorName'] ?? i['vendor']) == vendorName).toList();

    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(16)),
        child: const Center(child: Text('No items recorded from this vendor yet.', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey))),
      );
    }

    return Column(
      children: items.map((item) {
        final int stock = (item['openingStockQty'] ?? item['stock'] ?? 0).toInt();
        final bool isSoldOut = stock <= 0;

        return Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: isSoldOut ? Colors.red[50] : Colors.white, 
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSoldOut ? Colors.red[100]! : Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: (isSoldOut ? Colors.red : const Color(0xFF1A237E)).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(isSoldOut ? Icons.warning_amber_rounded : Icons.inventory_2_outlined, size: 20, color: isSoldOut ? Colors.red : const Color(0xFF1A237E)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['itemName'].toString(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    if (isSoldOut)
                      const Text('SOLD OUT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.red, letterSpacing: 0.5))
                    else
                      Text('Stock: $stock', style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Text('₹${item['purchasePrice'] ?? item['powerSpecs']?['purchasePrice'] ?? item['salePrice'] ?? 0}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isSoldOut ? Colors.red[700] : const Color(0xFF1A237E))),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _confirmDelete(BuildContext context, String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            const Text('Delete Vendor', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text('Are you sure you want to delete "$name" from your master list? This action cannot be undone.'),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog
              
              // Show progress
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (loadingCtx) => const Center(child: CircularProgressIndicator()),
              );

              final success = await _masterDataService.deleteVendor(id);
              
              if (context.mounted) {
                Navigator.pop(context); // Close loading spinner
                if (success) {
                  widget.onUpdate(); // Trigger list refresh
                  Navigator.pop(context); // Go back to Master list screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Vendor "$name" deleted successfully'),
                      backgroundColor: Colors.red,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to delete vendor. Please try again.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _payTypePill(bool isSelected, String label, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1A237E) : Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? const Color(0xFF1A237E) : Colors.grey[300]!),
          ),
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _quickPayButton(BuildContext pageCtx, BuildContext sheetCtx, String mode, Color color, IconData icon, double Function() getAmount) {
    return InkWell(
      onTap: () async {
        final double amount = getAmount();
        if (amount <= 0) {
          ScaffoldMessenger.of(pageCtx).showSnackBar(
            const SnackBar(content: Text('Please enter a valid payment amount'), backgroundColor: Colors.orange)
          );
          return;
        }

        // Show progress spinner
        showDialog(
          context: pageCtx,
          barrierDismissible: false,
          builder: (loadingCtx) => const Center(child: CircularProgressIndicator()),
        );

        final String vId = widget.vendor['id']?.toString() ?? '';
        final success = await _masterDataService.payVendor(vId, amount, mode, 'Settle via $mode');

        if (pageCtx.mounted) {
          Navigator.pop(pageCtx); // Close loading spinner
          Navigator.pop(sheetCtx); // Close sheet

          if (success) {
            setState(() {
              if (_detailedVendor != null) {
                final currentOut = (_detailedVendor!['outstanding'] ?? 0).toDouble();
                _detailedVendor!['outstanding'] = (currentOut - amount).clamp(0.0, double.infinity);
              }
            });

            ScaffoldMessenger.of(pageCtx).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.white),
                    const SizedBox(width: 12),
                    Text('Settle of ₹${amount.toStringAsFixed(0)} via $mode recorded!'),
                  ],
                ),
                backgroundColor: color,
                behavior: SnackBarBehavior.floating,
              ),
            );
            widget.onUpdate();

            // Dynamic WhatsApp Receipt Generation & Redirect
            try {
              final String vendorName = _detailedVendor?['name'] ?? widget.vendor['name'] ?? 'Vendor';
              final String vendorPhone = _detailedVendor?['phone'] ?? widget.vendor['phone'] ?? '9123456789';
              
              String cleanPhone = vendorPhone.replaceAll(RegExp(r'\D'), '');
              if (cleanPhone.startsWith('91') && cleanPhone.length > 10) {
                // already has country code
              } else {
                cleanPhone = '91$cleanPhone';
              }

              final double remainingOut = (_detailedVendor?['outstanding'] ?? 0).toDouble();
              final String msg = "Hello $vendorName,\n\nWe have successfully recorded a payment of *₹${amount.toStringAsFixed(0)}* via *$mode* on ${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}.\n\n*Remaining Outstanding:* ₹${remainingOut.toStringAsFixed(0)}\n\nPlease confirm receipt.\n\nThank you!";
              
              final encodedMsg = Uri.encodeComponent(msg);
              final url = "https://wa.me/$cleanPhone?text=$encodedMsg";
              
              if (await canLaunchUrl(Uri.parse(url))) {
                await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              }
            } catch (waErr) {
              debugPrint('⚠️ Error launching WhatsApp receipt: $waErr');
            }
          } else {
            ScaffoldMessenger.of(pageCtx).showSnackBar(
              const SnackBar(
                content: Text('Failed to record payment with backend. Please try again.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              mode, 
              style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  void _showPayVendorSheet(BuildContext context, String vendorName, double outstandingAmount) {
    String selectedOption = 'Full'; // 'Full', 'Half', 'Custom'
    final TextEditingController customController = TextEditingController(text: outstandingAmount.toStringAsFixed(0));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          double getAmount() {
            if (selectedOption == 'Full') return outstandingAmount;
            if (selectedOption == 'Half') return outstandingAmount / 2;
            return double.tryParse(customController.text) ?? 0;
          }

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.payment, color: Colors.green),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Settle Outstanding Balance', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text('Record payment for $vendorName', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Select Settle Type:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _payTypePill(
                        selectedOption == 'Full', 
                        'Full (₹${outstandingAmount.toStringAsFixed(0)})',
                        () => setSheetState(() => selectedOption = 'Full'),
                      ),
                      const SizedBox(width: 8),
                      _payTypePill(
                        selectedOption == 'Half', 
                        'Half (₹${(outstandingAmount / 2).toStringAsFixed(0)})',
                        () => setSheetState(() => selectedOption = 'Half'),
                      ),
                      const SizedBox(width: 8),
                      _payTypePill(
                        selectedOption == 'Custom', 
                        'Custom',
                        () => setSheetState(() => selectedOption = 'Custom'),
                      ),
                    ],
                  ),
                  if (selectedOption == 'Custom') ...[
                    const SizedBox(height: 16),
                    const Text('Enter Custom Amount (₹)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: customController,
                      keyboardType: TextInputType.number,
                      onChanged: (val) => setSheetState(() {}),
                      decoration: InputDecoration(
                        prefixText: '₹ ',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Settle Amount:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                        Text('₹${getAmount().toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.red, fontSize: 18)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Select Payment Mode to Settle:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _quickPayButton(context, ctx, 'UPI', Colors.deepPurple, Icons.qr_code_scanner_outlined, getAmount),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _quickPayButton(context, ctx, 'Cash', Colors.green, Icons.money_outlined, getAmount),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _quickPayButton(context, ctx, 'Card', Colors.blue, Icons.credit_card_outlined, getAmount),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, String name, double outstanding) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _confirmDelete(context, widget.vendor['id']?.toString() ?? '', name),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF1A237E)),
                foregroundColor: const Color(0xFF1A237E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () => _showOutstandingSheet(context, name, outstanding),
              child: const Text('View Ledger', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () => _showPayVendorSheet(context, name, outstanding),
              child: const Text('Pay Vendor', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditVendorSheet(BuildContext context, Map<String, dynamic> vendor) {
    final String id = vendor['id']?.toString() ?? '';
    final nameController = TextEditingController(text: vendor['name']?.toString() ?? '');
    final contactController = TextEditingController(text: vendor['contactPerson']?.toString() ?? '');
    final phoneController = TextEditingController(text: vendor['phone']?.toString() ?? '');
    final emailController = TextEditingController(text: vendor['email']?.toString() ?? '');
    final addressController = TextEditingController(text: vendor['address']?.toString() ?? '');
    final dobController = TextEditingController(text: vendor['dob']?.toString() ?? '');
    final gstinController = TextEditingController(text: vendor['gstin']?.toString() ?? '');
    final outstandingController = TextEditingController(text: (vendor['outstanding'] ?? '0').toString());

    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 16,
            left: 20,
            right: 20,
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFF1A237E).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.edit_outlined, color: Color(0xFF1A237E)),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Edit Vendor Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('Update account information and balances', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildEditField('Vendor Name', nameController, Icons.business),
                      const SizedBox(height: 16),
                      _buildEditField('Contact Person', contactController, Icons.person),
                      const SizedBox(height: 16),
                      _buildEditField('Phone Number', phoneController, Icons.phone),
                      const SizedBox(height: 16),
                      _buildEditField('Email Address', emailController, Icons.email),
                      const SizedBox(height: 16),
                      _buildEditField('Address', addressController, Icons.location_on),
                      const SizedBox(height: 16),
                      _buildEditField('Date of Birth / Incorporation', dobController, Icons.cake),
                      const SizedBox(height: 16),
                      _buildEditField('GSTIN', gstinController, Icons.receipt),
                      const SizedBox(height: 16),
                      _buildEditField('Outstanding Balance (₹)', outstandingController, Icons.account_balance_wallet, isNumeric: true),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A237E),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          onPressed: isSaving ? null : () async {
                            setSheetState(() => isSaving = true);
                            final Map<String, dynamic> payload = {
                              'name': nameController.text.trim(),
                              'contactPerson': contactController.text.trim(),
                              'phone': phoneController.text.trim(),
                              'email': emailController.text.trim(),
                              'address': addressController.text.trim(),
                              'dob': dobController.text.trim(),
                              'gstin': gstinController.text.trim(),
                              'outstanding': double.tryParse(outstandingController.text.trim()) ?? 0.0,
                            };

                            final success = await _masterDataService.updateVendor(id, payload);
                            if (success) {
                              Navigator.pop(ctx);
                              _loadVendorDetails();
                              widget.onUpdate();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Vendor details updated successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              setSheetState(() => isSaving = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Failed to update vendor. Please try again.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          child: isSaving
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                              : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 24),
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

  Widget _buildEditField(String label, TextEditingController controller, IconData icon, {bool isNumeric = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1A237E), width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
