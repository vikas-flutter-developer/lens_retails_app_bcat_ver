import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/master_data_service.dart';
import '../../../core/mock/mock_data.dart';
import 'vendor_details_screen.dart';

class VendorMasterScreen extends StatefulWidget {
  final String? initialVendorName;
  const VendorMasterScreen({super.key, this.initialVendorName});

  @override
  State<VendorMasterScreen> createState() => _VendorMasterScreenState();
}

class _VendorMasterScreenState extends State<VendorMasterScreen> {
  final MasterDataService _masterDataService = MasterDataService();
  List<Map<String, dynamic>> _vendors = [];
  bool _isLoading = true;

  List<Map<String, dynamic>> _filteredVendors = [];
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadVendors();
  }

  Future<void> _loadVendors() async {
    setState(() => _isLoading = true);
    final data = await _masterDataService.fetchVendors();
    setState(() {
      _vendors = data;
      _filterVendors();
      _isLoading = false;
    });
  }

  void _filterVendors() {
    setState(() {
      _filteredVendors = _vendors.where((v) {
        final String name = (v['name'] ?? v['Name'] ?? '').toString().toLowerCase();
        return name.contains(_searchQuery.toLowerCase());
      }).toList();
    });
  }

  void _showVendorForm([Map<String, dynamic>? vendor]) {
    final nameCtrl = TextEditingController(text: vendor?['name'] ?? vendor?['Name']);
    final printNameCtrl = TextEditingController(text: vendor?['printName'] ?? vendor?['PrintName'] ?? vendor?['name'] ?? vendor?['Name']);
    final aliasCtrl = TextEditingController(text: vendor?['alias'] ?? vendor?['Alias']);
    final accountIdCtrl = TextEditingController(text: vendor?['accountId'] ?? vendor?['AccountId'] ?? 'MOCK-${1000 + _vendors.length}');
    final groupCtrl = TextEditingController(text: vendor?['group'] ?? 'Purchase Account');
    final stationCtrl = TextEditingController(text: vendor?['station'] ?? 'Local');
    final contactPersonCtrl = TextEditingController(text: vendor?['contactPerson'] ?? 'Admin Manager');
    final phoneCtrl = TextEditingController(text: vendor?['phone'] ?? vendor?['MobileNumber']);
    final emailCtrl = TextEditingController(text: vendor?['email'] ?? vendor?['Email']);
    String accountType = vendor?['accountType'] ?? 'Purchase';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.9,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(color: Color(0xFF1A237E), borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.business_center, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Add Account', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('Synchronized with web master data', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('BASIC INFORMATION'),
                    _buildField(nameCtrl, 'Name *', Icons.storefront),
                    const SizedBox(height: 16),
                    _buildField(printNameCtrl, 'Print Name *', Icons.print_outlined),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildField(accountIdCtrl, 'Account Id *', Icons.fingerprint, enabled: false)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildField(aliasCtrl, 'Alias', Icons.label_outline)),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _sectionLabel('GROUPS & STATIONS'),
                    Row(
                      children: [
                        Expanded(child: _buildField(groupCtrl, 'Groups *', Icons.group_work_outlined)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildField(stationCtrl, 'Stations *', Icons.location_on_outlined)),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _sectionLabel('CONTACT & IDs'),
                    _buildField(contactPersonCtrl, 'Contact Person', Icons.person_outline),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildField(phoneCtrl, 'Mobile Number', Icons.phone_android_outlined, isPhone: true)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildField(emailCtrl, 'Email', Icons.alternate_email)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown('Account Type', accountType, ['Purchase', 'Sales', 'Service'], (val) {
                      accountType = val!;
                    }),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            // Actions
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Discard', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A237E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        if (nameCtrl.text.isNotEmpty) {
                          final data = {
                            'name': nameCtrl.text,
                            'printName': printNameCtrl.text,
                            'accountId': accountIdCtrl.text,
                            'alias': aliasCtrl.text,
                            'group': groupCtrl.text,
                            'station': stationCtrl.text,
                            'contactPerson': contactPersonCtrl.text,
                            'phone': phoneCtrl.text,
                            'email': emailCtrl.text,
                            'accountType': accountType,
                          };
                          bool success = await _masterDataService.createVendor(data);
                          if (success && mounted) {
                            Navigator.pop(ctx);
                            _loadVendors();
                          }
                        }
                      },
                      child: const Text('Save Account', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1A237E), letterSpacing: 0.5)),
          const SizedBox(width: 8),
          Expanded(child: Divider(color: Colors.grey[200])),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon, {bool isPhone = false, bool enabled = true}) {
    return TextField(
      controller: ctrl,
      enabled: enabled,
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFF1A237E)),
        border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey[300]!)),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey[300]!)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF1A237E))),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: const TextStyle(fontSize: 14)))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
        prefixIcon: const Icon(Icons.category_outlined, size: 20, color: Color(0xFF1A237E)),
        border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey[300]!)),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Vendor Master', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.add_circle_outline, size: 28), onPressed: () => _showVendorForm()),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: const Color(0xFF1A237E),
                child: TextField(
                  onChanged: (val) {
                    _searchQuery = val;
                    _filterVendors();
                  },
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search labs or suppliers...',
                    hintStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
              Expanded(
                child: _filteredVendors.isEmpty 
                  ? const Center(child: Text('No vendors found matching search.'))
                  : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredVendors.length,
                  itemBuilder: (context, index) {
                    final vendor = _filteredVendors[index];
                    final String name = (vendor['name'] ?? vendor['Name'] ?? 'Unnamed').toString();
                    final bool isHighlight = widget.initialVendorName == name;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: isHighlight ? Border.all(color: const Color(0xFF1A237E), width: 2) : null,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
                      ),
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => VendorDetailsScreen(
                              vendor: vendor, 
                              onUpdate: _loadVendors,
                            )),
                          );
                        },
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF1A237E).withOpacity(0.1),
                          child: Text(name[0], style: const TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.bold)),
                        ),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(vendor['email'] ?? vendor['Email'] ?? 'contact@lab.com', style: const TextStyle(fontSize: 12)),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
    );
  }
}
