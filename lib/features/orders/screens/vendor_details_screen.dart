import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/master_data_service.dart';
import '../../../core/mock/mock_data.dart';

class VendorDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> vendor;
  final Function() onUpdate;

  const VendorDetailsScreen({
    super.key, 
    required this.vendor, 
    required this.onUpdate
  });

  void _launchWhatsApp(String phone) async {
    final url = "https://wa.me/91$phone";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  void _launchCall(String phone) async {
    final url = "tel:$phone";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  @override
  Widget build(BuildContext context) {
    final String name = (vendor['name'] ?? vendor['Name'] ?? 'Unnamed').toString();
    final String phone = vendor['phone'] ?? vendor['MobileNumber'] ?? '9876543210';
    final String email = vendor['email'] ?? vendor['Email'] ?? 'contact@lab.com';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Vendor Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(name, email, phone),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMetricsRow(),
                  const SizedBox(height: 24),
                  const Text('BUSINESS INFORMATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                  const SizedBox(height: 12),
                  _buildInfoCard(vendor),
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
      bottomNavigationBar: _buildBottomActions(context, name),
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
                child: Text(name[0], style: const TextStyle(fontSize: 30, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text(email, style: const TextStyle(color: Colors.white70)),
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

  Widget _buildMetricsRow() {
    return Row(
      children: [
        _metricBox('Total Orders', '24', Icons.shopping_bag_outlined, Colors.blue),
        const SizedBox(width: 12),
        _metricBox('Outstanding', '₹12,450', Icons.account_balance_wallet_outlined, Colors.red),
      ],
    );
  }

  Widget _metricBox(String label, String value, IconData icon, Color color) {
    return Expanded(
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
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(Map<String, dynamic> vendor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _infoRow(Icons.person_outline, 'Contact Person', vendor['contactPerson'] ?? 'Admin Manager'),
          const Divider(height: 24),
          _infoRow(Icons.location_on_outlined, 'Address', vendor['address'] ?? vendor['Address'] ?? 'Not set'),
          const Divider(height: 24),
          _infoRow(Icons.receipt_long_outlined, 'GSTIN', vendor['gstin'] ?? vendor['GSTIN'] ?? 'N/A'),
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
              Text('₹${item['purchasePrice']}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isSoldOut ? Colors.red[700] : const Color(0xFF1A237E))),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomActions(BuildContext context, String name) {
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
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {},
              child: const Text('View Full Ledger', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
