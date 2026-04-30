import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/inventory_service.dart';
import '../../pos/screens/barcode_scanner_screen.dart';
import '../../orders/services/master_data_service.dart';
import '../../orders/screens/vendor_master_screen.dart';

class LocalInventoryScreen extends StatefulWidget {
  const LocalInventoryScreen({super.key});
// ... (rest of the class)

  @override
  State<LocalInventoryScreen> createState() => _LocalInventoryScreenState();
}

class _LocalInventoryScreenState extends State<LocalInventoryScreen> {
  final InventoryService _inventoryService = InventoryService();
  final MasterDataService _masterDataService = MasterDataService();
  final TextEditingController _barcodeController = TextEditingController();
  
  List<Map<String, dynamic>> _inventory = [];
  List<Map<String, dynamic>> _vendors = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';
  DateTime? _startDate;
  DateTime? _endDate;

  bool _isAscending = false; // Default to High to Low (Newest first)

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    setState(() => _isLoading = true);
    final invData = await _inventoryService.fetchAllItems();
    final venData = await _masterDataService.fetchVendors();
    setState(() {
      _inventory = invData;
      _vendors = venData;
      _isLoading = false;
    });
  }

  Future<void> _fetchData() async {
    final data = await _inventoryService.fetchAllItems();
    setState(() {
      _inventory = data;
    });
  }

  List<Map<String, dynamic>> _getFilteredItems(List<Map<String, dynamic>> items) {
    try {
      final List<Map<String, dynamic>> filtered = items.where((item) {
        // Category Filter
        final String itemCategory = (item['groupName'] ?? item['category'] ?? '').toString().toLowerCase();
        final String selectedCat = _selectedCategory.toLowerCase();
        final bool matchesCategory = selectedCat == 'all' || itemCategory == selectedCat;
        
        // Search Filter
        final String query = _barcodeController.text.toLowerCase();
        final String itemName = (item['itemName'] ?? item['name'] ?? '').toString().toLowerCase();
        final bool matchesSearch = query.isEmpty || itemName.contains(query);
            
        // Date Filter
        bool matchesDate = true;
        if (_startDate != null || _endDate != null) {
          final String? dateStr = item['receivedDate']?.toString();
          if (dateStr != null && dateStr.isNotEmpty) {
            try {
              final datePart = dateStr.split(' ').first;
              final DateTime arrivalDate = DateTime.parse(datePart);
              
              if (_startDate != null) {
                final start = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
                if (arrivalDate.isBefore(start)) matchesDate = false;
              }
              if (_endDate != null) {
                final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
                if (arrivalDate.isAfter(end)) matchesDate = false;
              }
            } catch (e) {
              matchesDate = false; 
            }
          } else {
            matchesDate = false;
          }
        }
            
        return matchesCategory && matchesSearch && matchesDate;
      }).toList();

      // SORTING LOGIC
      filtered.sort((a, b) {
        final String dateAStr = (a['receivedDate']?.toString() ?? '1900-01-01').split(' ').first;
        final String dateBStr = (b['receivedDate']?.toString() ?? '1900-01-01').split(' ').first;
        final DateTime dateA = DateTime.tryParse(dateAStr) ?? DateTime(1900);
        final DateTime dateB = DateTime.tryParse(dateBStr) ?? DateTime(1900);
        
        return _isAscending ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
      });

      return filtered;
    } catch (e) {
      return [];
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime(2027),
      initialDateRange: _startDate != null && _endDate != null 
          ? DateTimeRange(start: _startDate!, end: _endDate!) 
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1A237E),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    super.dispose();
  }

  void _showAddItemSheet() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController priceController = TextEditingController();
    final TextEditingController stockController = TextEditingController();
    final TextEditingController groupController = TextEditingController();
    final TextEditingController alertController = TextEditingController(text: '5');
    String selectedUnit = 'Pcs';
    String? selectedVendor = _vendors.isNotEmpty ? _vendors.first['name']?.toString() : 'Unknown Vendor';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const Text('Add New Product', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
                const SizedBox(height: 24),
                
                _buildModernField(nameController, 'Product Name', Icons.inventory_2_outlined),
                const SizedBox(height: 16),

                const Text('Supplier / Vendor', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedVendor,
                      isExpanded: true,
                      hint: const Text('Select Vendor'),
                      items: _vendors.map((v) {
                        final String name = (v['name'] ?? v['Name'] ?? 'Unnamed').toString();
                        return DropdownMenuItem(value: name, child: Text(name));
                      }).toList(),
                      onChanged: (val) => setModalState(() => selectedVendor = val),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(child: _buildModernField(groupController, 'Category', Icons.category_outlined)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Unit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedUnit,
                                isExpanded: true,
                                items: ['Pcs', 'Pairs', 'Boxes', 'Lenses'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                                onChanged: (val) => setModalState(() => selectedUnit = val!),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(child: _buildModernField(priceController, 'Price (₹)', Icons.payments_outlined, isNumber: true)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildModernField(stockController, 'Stock Qty', Icons.warehouse_outlined, isNumber: true)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildModernField(alertController, 'Alert Level', Icons.notification_important_outlined, isNumber: true),
                
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A237E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  onPressed: () async {
                      if (nameController.text.isNotEmpty) {
                        final success = await _inventoryService.addItem({
                          'itemName': nameController.text,
                          'groupName': groupController.text,
                          'purchasePrice': double.tryParse(priceController.text) ?? 0.0,
                          'openingStockQty': int.tryParse(stockController.text) ?? 0,
                          'alertQty': int.tryParse(alertController.text) ?? 5,
                          'unit': selectedUnit,
                          'vendorName': selectedVendor,
                          'receivedDate': DateFormat('yyyy-MM-dd HH:mm a').format(DateTime.now()),
                        });
                        if (success && mounted) {
                          Navigator.pop(ctx);
                          _fetchData();
                        }
                      }
                    },
                    child: const Text('Add to Inventory', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernField(TextEditingController controller, String label, IconData icon, {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: const Color(0xFF1A237E)),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1A237E), width: 1.5)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          elevation: 0,
          title: const Text('Store Inventory', style: TextStyle(fontWeight: FontWeight.bold)),
          bottom: TabBar(
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicator: const UnderlineTabIndicator(
              borderSide: BorderSide(width: 4, color: Color(0xFFD4AF37)),
              insets: EdgeInsets.symmetric(horizontal: 40),
            ),
            tabs: const [
              Tab(text: 'ALL STOCK'),
              Tab(text: 'LOW ALERTS'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 28),
              onPressed: _showAddItemSheet,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A237E)))
          : TabBarView(
          children: [
            Column(
              children: [
                _buildSearchAndFilters(),
                if (_startDate != null) _buildActiveDateFilter(),
                Expanded(child: _buildInventoryList()),
              ],
            ),
            _buildAlertsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          TextField(
            controller: _barcodeController,
            onChanged: (val) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search by brand or model...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF1A237E)),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: ['All', 'Frames', 'Lenses', 'Contact Lenses', 'Solutions', 'Accessories'].map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(cat, style: TextStyle(
                            fontSize: 11, 
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                          )),
                          selected: isSelected,
                          onSelected: (val) => setState(() => _selectedCategory = cat),
                          backgroundColor: Colors.grey[100],
                          selectedColor: const Color(0xFF1A237E),
                          checkmarkColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide.none),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildCircleButton(
                icon: Icons.calendar_month_outlined, 
                isSelected: _startDate != null,
                onTap: _selectDateRange
              ),
              const SizedBox(width: 8),
              _buildCircleButton(
                icon: _isAscending ? Icons.arrow_downward : Icons.arrow_upward, 
                onTap: () => setState(() => _isAscending = !_isAscending)
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({required IconData icon, bool isSelected = false, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A237E) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: isSelected ? Colors.white : const Color(0xFF1A237E)),
      ),
    );
  }

  Widget _buildActiveDateFilter() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.date_range, size: 16, color: Color(0xFF1A237E)),
          const SizedBox(width: 8),
          Text(
            'Showing: ${DateFormat('dd MMM').format(_startDate!)} - ${DateFormat('dd MMM').format(_endDate!)}',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() { _startDate = null; _endDate = null; }),
            child: const Icon(Icons.close, size: 16, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryList() {
    final filtered = _getFilteredItems(_inventory);
    if (filtered.isEmpty) {
      return const Center(child: Text('No products found matching your filter.', style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final item = filtered[index];
        final int stock = (item['openingStockQty'] ?? item['stock'] ?? 0).toInt();
        final int alertLevel = (item['alertQty'] ?? 5).toInt();
        final bool isLow = stock < alertLevel;
        final String vendor = item['vendorName'] ?? item['vendor'] ?? item['Name'] ?? 'No Vendor';
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isLow ? Colors.red : const Color(0xFF1A237E)).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                item['groupName'] == 'Frames' ? Icons.visibility_outlined : Icons.inventory_2_outlined, 
                color: isLow ? Colors.red : const Color(0xFF1A237E), 
                size: 22
              ),
            ),
            title: Text(
              (item['itemName'] ?? 'Unknown').toString(), 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  '${item['groupName']} • ₹${item['purchasePrice']}', 
                  style: TextStyle(fontSize: 11, color: Colors.grey[600])
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    'Arrived: ${item['receivedDate']}', 
                    style: TextStyle(fontSize: 9, color: Colors.grey[500], fontStyle: FontStyle.italic)
                  ),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$stock ${item['unit'] ?? 'Pcs'}', 
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: isLow ? Colors.red : Colors.green[700])
                ),
                Text(
                  isLow ? 'LOW STOCK' : 'IN STOCK', 
                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: isLow ? Colors.red : Colors.grey)
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlertsTab() {
    final alerts = _inventory.where((item) => (item['openingStockQty'] ?? item['stock'] ?? 0) < (item['alertQty'] ?? 5)).toList();
    if (alerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 60, color: Colors.green[200]),
            const SizedBox(height: 16),
            const Text('All stock levels are healthy!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: alerts.length,
      itemBuilder: (context, index) {
        final item = alerts[index];
        final String vendor = item['vendorName'] ?? item['vendor'] ?? item['Name'] ?? 'No Vendor';
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red[100]!),
          ),
          child: ListTile(
            leading: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            title: Text(item['itemName'].toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            subtitle: Text('Stock: ${item['openingStockQty']} | Alert: ${item['alertQty'] ?? 5}', style: TextStyle(color: Colors.red[700], fontSize: 11)),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => VendorMasterScreen(initialVendorName: vendor)),
                );
              },
              child: const Text('RESTOCK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
        );
      },
    );
  }
}
