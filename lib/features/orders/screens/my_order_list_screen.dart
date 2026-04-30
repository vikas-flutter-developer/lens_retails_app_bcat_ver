import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/order_card.dart';
import '../../common/skeleton_loader.dart';
import '../../auth/services/auth_service.dart';
import '../services/order_service.dart';

class MyOrderListScreen extends StatefulWidget {
  final String? initialStatus;
  const MyOrderListScreen({super.key, this.initialStatus});

  @override
  State<MyOrderListScreen> createState() => _MyOrderListScreenState();
}

class _MyOrderListScreenState extends State<MyOrderListScreen> {
  bool _isLoading = true;
  final OrderService _orderService = OrderService();
  String? _errorMessage;
  final _fromDateController = TextEditingController();
  final _toDateController = TextEditingController();
  final _searchController = TextEditingController();
  Timer? _refreshTimer;

  final List<Map<String, dynamic>> _allOrders = [];

  List<Map<String, dynamic>> _filteredOrders = [];
  
  String _selectedType = 'All';
  late String _selectedStatus; // Late initialization

  final List<String> _statusOptions = [
    'All', 'Pending', 'In Progress', 'Sent to Lab', 'Received', 'Fitting', 'Done', 'Shipped', 'Delivered', 'Cancelled', 'Rejected'
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize with dynamic dates (First day of month to Today)
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    
    _fromDateController.text = "${firstDay.day.toString().padLeft(2, '0')}-${firstDay.month.toString().padLeft(2, '0')}-${firstDay.year}";
    _toDateController.text = "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";

    _selectedStatus = widget.initialStatus ?? 'All'; // Use passed status or default
    _searchController.addListener(_filterOrders);
    _loadData();
    
    // Auto-refresh every 30 seconds
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _loadData(),
    );
  }

  Future<void> _loadData() async {
    try {
      // Fetch Orders directly. Assumes valid token exists from Login.
      final orders = await _orderService.fetchOrders();
      
      if (mounted) {
        setState(() {
          _allOrders.clear();
          _allOrders.addAll(orders);
          _isLoading = false;
        });
        // Apply existing filters (including initial status passed from dashboard)
        _filterOrders();
      }
    } catch (e) {
      debugPrint('⚠️ [OrderList] API failed: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Failed to load orders: $e";
        });
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error connecting to API: $e'),
              backgroundColor: Colors.red,
            )
        );
      }
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchController.dispose();
    _fromDateController.dispose();
    _toDateController.dispose();
    super.dispose();
  }

  void _filterOrders() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredOrders = _allOrders.where((order) {
        final matchesSearch = (order['customer']?.toLowerCase() ?? '').contains(query) || 
                              (order['invoice']?.toLowerCase() ?? '').contains(query);
        
        final matchesType = _selectedType == 'All' || (order['type'] == _selectedType);
        
        final status = order['status']?.toString() ?? '';
        final matchesStatus = _selectedStatus == 'All' || 
                              (status.toLowerCase() == _selectedStatus.toLowerCase()); // Case insensitive match
        
        return matchesSearch && matchesType && matchesStatus;
      }).toList();
    });
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      controller.text = "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Order List', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1A237E),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Filter Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 800) {
                        return _buildDesktopFilterRow();
                    } else {
                        return _buildMobileFilterColumn();
                    }
                  },
                ),
              ),
            ),
          ),
          
          // Order Grid/List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: _isLoading 
                ? _buildSkeletonGrid()
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center))
                    : _filteredOrders.isEmpty 
                      ? const Center(child: Text('No orders found', style: TextStyle(color: Colors.grey)))
                      : LayoutBuilder(
                  builder: (context, constraints) {
                      // Use ListView for mobile (dynamic height), GridView for desktop
                      if (constraints.maxWidth < 800) {
                        return ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredOrders.length,
                          separatorBuilder: (ctx, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            return OrderCard(
                              order: _filteredOrders[index],
                              onDelete: () async {
                                await Future.delayed(const Duration(milliseconds: 500));
                                await _loadData();
                              },
                            );
                          },
                        );
                      }
                      
                      int crossAxisCount = constraints.maxWidth > 1200 ? 3 : 2;
                      double childAspectRatio = constraints.maxWidth > 1200 ? 1.7 : 2.1;
  
                      return GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            childAspectRatio: childAspectRatio,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: _filteredOrders.length,
                          itemBuilder: (context, index) {
                            return OrderCard(
                              order: _filteredOrders[index],
                              onDelete: () async {
                                // Small delay to allow backend to process deletion
                                await Future.delayed(const Duration(milliseconds: 500));
                                await _loadData();
                              },
                            );
                          },
                      );
                  }
                ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isFilterExpanded = false;

  Widget _buildDesktopFilterRow() {
    // Desktop: Keep as is but compact spacing
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: _buildDateInput('From Date', _fromDateController)),
        const SizedBox(width: 8),
        Expanded(child: _buildDateInput('To Date', _toDateController)),
        const SizedBox(width: 8),
        Expanded(
          child: _buildGenericDropdown(
            'Type', 
            _selectedType, 
            ['All', 'RX', 'Single Finish', 'Bulk'], 
            (v) { if(v!=null) setState(() => _selectedType = v); _filterOrders(); }
          )
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildGenericDropdown(
            'Status', 
            _selectedStatus, 
            _statusOptions, 
            (v) { if(v!=null) setState(() => _selectedStatus = v); _filterOrders(); }
          )
        ),
        const SizedBox(width: 8),
        Expanded(flex: 2, child: _buildSearchInput()),
        const SizedBox(width: 8),
        SizedBox(
            height: 48,
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))
                ),
                onPressed: _filterOrders, 
                child: const Text('Search')
            )
        ),
      ],
    );
  }
  
  Widget _buildMobileFilterColumn() {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           // Row 1: Search & Expand Button (Always Visible)
           Row(
               crossAxisAlignment: CrossAxisAlignment.center,
               children: [
                   Expanded(child: _buildSearchInput(hint: 'Search Customer/Invoice...', showSpacer: false)),
                   const SizedBox(width: 8),
                   IconButton(
                     icon: Icon(_isFilterExpanded ? Icons.filter_list_off : Icons.filter_list, color: Colors.blue),
                     onPressed: () => setState(() => _isFilterExpanded = !_isFilterExpanded),
                     tooltip: 'Toggle Filters',
                   ),
                   const SizedBox(width: 8),
                   ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))
                        ),
                        onPressed: _filterOrders, 
                        child: const Text('Search')
                    )
               ],
           ),
           
           // Collapsible Section
           if (_isFilterExpanded) ...[
             const SizedBox(height: 12),
             Row(
                 children: [
                     Expanded(child: _buildDateInput('From', _fromDateController)),
                     const SizedBox(width: 8),
                     Expanded(child: _buildDateInput('To', _toDateController)),
                 ],
             ),
             const SizedBox(height: 12),
             Row(
               children: [
                  Expanded(
                    child: _buildGenericDropdown(
                      'Type', 
                      _selectedType, 
                      ['All', 'RX', 'Single Finish', 'Bulk'], 
                      (v) { if(v!=null) setState(() => _selectedType = v); _filterOrders(); }
                    )
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildGenericDropdown(
                      'Status', 
                      _selectedStatus, 
                      _statusOptions, 
                      (v) { if(v!=null) setState(() => _selectedStatus = v); _filterOrders(); }
                    )
                  ),
               ],
             ),
           ],
        ],
    );
  }

  Widget _buildDateInput(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          readOnly: true,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            filled: true,
            fillColor: Colors.grey[200],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
          ),
          onTap: () => _selectDate(context, controller),
        ),
      ],
    );
  }

  Widget _buildGenericDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           // Use label as header
           Text(label, style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.w500)),
           const SizedBox(height: 4),
           DropdownButtonFormField<String>(
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Colors.grey)),
                filled: true,
                fillColor: Colors.white,
              ),
              initialValue: items.contains(value) ? value : items.first, // Safe fallback
              items: items.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis))).toList(),
              onChanged: onChanged,
              isExpanded: true, // Prevent overflow
           )
        ],
      );
  }

  Widget _buildSearchInput({String hint = 'Search', bool showSpacer = true}) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           if (showSpacer) const Text(' ', style: TextStyle(height: 1.5)), 
           TextFormField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: hint,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Colors.grey)),
              ),
           ),
        ],
      );
  }

  Widget _buildSkeletonGrid() {
      return LayoutBuilder(
        builder: (context, constraints) {
            int crossAxisCount = constraints.maxWidth > 1100 ? 3 : (constraints.maxWidth > 700 ? 2 : 1);
            double childAspectRatio = 1.3; 
            return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: childAspectRatio,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16
                ),
                itemCount: 6,
                itemBuilder: (context, index) {
                  return const ShimmerSkeleton(
                      width: double.infinity, 
                      height: double.infinity, 
                      borderRadius: BorderRadius.all(Radius.circular(16))
                  );
                },
            );
        }
      );
  }
}
