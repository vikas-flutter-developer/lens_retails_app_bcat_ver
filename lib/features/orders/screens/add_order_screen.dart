import 'dart:io'; 
import 'dart:async'; // Added for Timer
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../../../core/network/api_client.dart';
import '../services/master_data_service.dart';
import '../../auth/services/auth_service.dart';
import '../services/order_service.dart';
import '../services/customer_service.dart';
import '../../collections/services/collection_service.dart';
import '../../../core/config/app_config.dart';
import '../../../core/mock/mock_data.dart';

import '../widgets/lens_power_matrix_dialog.dart';
import '../../../core/widgets/responsive_row.dart';

class AddOrderScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const AddOrderScreen({super.key, this.onBack});

  @override
  State<AddOrderScreen> createState() => _AddOrderScreenState();
}

class _AddOrderScreenState extends State<AddOrderScreen>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;
  final MasterDataService _masterDataService = MasterDataService();
  final OrderService _orderService = OrderService();
  final CustomerService _customerService = CustomerService();
  final CollectionService _collectionService = CollectionService();
  
  final _formKey = GlobalKey<FormState>();
  Timer? _refreshTimer;

  // Master Data State
  String? _selectedCustomerId;
  List<Map<String, dynamic>> _lensGroups = [];
  List<Map<String, dynamic>> _vendors = [];
  List<Map<String, dynamic>> _items = [];
  String? _selectedVendorId;
  String? _selectedItemId;
  String? _selectedFrameId; // For "BOTH" mode
  final TextEditingController _rFrameQtyController = TextEditingController(text: '1');
  final TextEditingController _lFrameQtyController = TextEditingController(text: '1');
  bool _isRightFrameSelected = true;
  bool _isLeftFrameSelected = true;
  double _framePrice = 0.0; // For "BOTH" mode
  bool _isLoadingMasterData = false;
  bool _isDataLoaded = false;
  String? _editingOrderId = null;
  String _selectedCategory = 'Lens'; 
  bool _shouldSaveCustomer = true;

  // Controllers
  final _customerNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _addressController = TextEditingController();
  final _remarksController = TextEditingController();
  final _dobController = TextEditingController();
  final _dateController = TextEditingController(text: DateTime.now().toString().split(' ')[0]);
  final _deliveryDateController = TextEditingController(text: DateTime.now().add(const Duration(days: 7)).toString().split(' ')[0]);
  final _orderIdController = TextEditingController(text: 'Loading...');
  final _billSeriesController = TextEditingController(text: 'ORD_25-26');
  final _itemNameController = TextEditingController();
  final _mainCategoryController = TextEditingController();
  final _subCategoryController = TextEditingController();

  // Eye Data Controllers (Right)
  final _rSphController = TextEditingController();
  final _rCylController = TextEditingController();
  final _rAxisController = TextEditingController();
  final _rAddController = TextEditingController();
  final _rQtyController = TextEditingController(text: '1');

  // Eye Data Controllers (Left)
  final _lSphController = TextEditingController();
  final _lCylController = TextEditingController();
  final _lAxisController = TextEditingController();
  final _lAddController = TextEditingController();
  final _lQtyController = TextEditingController(text: '1');

  // Price Controllers (editable)
  final _rEyePriceController = TextEditingController(text: '0.00');
  final _lEyePriceController = TextEditingController(text: '0.00');
  double _rEyePrice = 0.0;
  double _lEyePrice = 0.0;
  double _totalPrice = 0.0;
  final _advancePaidController = TextEditingController(text: '0.00');
  Map<String, dynamic>? _selectedItem;
  
  // Current User Info for Auto-fill
  String _currentUserName = '';
  String _currentUserMobile = '';
  String _currentUserAddress = '';
  String _currentUserDetailsText = 'Loading profile...';

  // Dynamic State Maps
  final Map<String, TextEditingController> _extraTextControllers = {};
  final Map<String, String?> _extraDropdownValues = {};
  
  // Bulk Order State
  final List<Map<String, dynamic>> _bulkItems = [];
  final List<Map<String, dynamic>> _singleFinishItems = [];
  List<Map<String, dynamic>> _customerHistory = [];
  // Helper for API Date Format - Returns ISO 8601 format for MongoDB
  String formatDateForApi(String uiDate) {
    try {
      if (uiDate.isEmpty) return DateTime.now().toUtc().toIso8601String();
      final parts = uiDate.split('-');
      if (parts.length == 3) {
         // Check if first part is Year (YYYY-MM-DD)
         if (parts[0].length == 4) {
             final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
             return dt.toUtc().toIso8601String();
         }
         // Assume DD-MM-YYYY
         final dt = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
         return dt.toUtc().toIso8601String();
      }
      return DateTime.now().toUtc().toIso8601String(); // Fallback
    } catch (_) {
      return DateTime.now().toUtc().toIso8601String();
    }
  }

  // Camera & Voice State
  final ImagePicker _picker = ImagePicker();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isFabExpanded = false;

  bool _isRightSelected = true;
  bool _isLeftSelected = true;

  // Calculate and update prices when lens is selected
  void _updatePricesFromItem(Map<String, dynamic> item) {
    final salePrice = double.tryParse(item['salePrice']?.toString() ?? '0') ?? 0.0;
    
    setState(() {
      _selectedItem = item;
      if (_isRightSelected) {
        _rEyePrice = salePrice;
        _rEyePriceController.text = salePrice.toStringAsFixed(2);
      }
      if (_isLeftSelected) {
        _lEyePrice = salePrice;
        _lEyePriceController.text = salePrice.toStringAsFixed(2);
      }
      _calculateTotalPrice();
    });
  }

  void _calculateTotalPrice() {
    double total = 0.0;
    
    // Always sync price variables from controllers
    _rEyePrice = double.tryParse(_rEyePriceController.text) ?? _rEyePrice;
    _lEyePrice = double.tryParse(_lEyePriceController.text) ?? _lEyePrice;
    
    if (_tabController.index == 0) {
       // RX Tab: Calculate from manual controllers
       if (_isRightSelected) {
         total += _rEyePrice * (int.tryParse(_rQtyController.text) ?? 1);
       }
       if (_isLeftSelected) {
         total += _lEyePrice * (int.tryParse(_lQtyController.text) ?? 1);
       }
       if (_selectedCategory == 'Both') {
         double frameTotal = 0.0;
         if (_isRightFrameSelected) frameTotal += _framePrice * (int.tryParse(_rFrameQtyController.text) ?? 1);
         if (_isLeftFrameSelected) frameTotal += _framePrice * (int.tryParse(_lFrameQtyController.text) ?? 1);
         total += frameTotal;
       }
    } else if (_tabController.index == 1) {
       // Single Finish Tab: Sum list items
       for (var item in _singleFinishItems) {
         total += double.tryParse(item['totalAmount']?.toString() ?? '0') ?? 0;
       }
    } else {
       // Bulk Tab: Sum list items
       for (var item in _bulkItems) {
         total += double.tryParse(item['totalAmount']?.toString() ?? '0') ?? 0;
       }
    }
    _totalPrice = total;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: 0,

    ); // Default to RX
    _loadMasterData();
    _fetchNextOrderId();
    _loadCurrentUserInfo();
    
    // Auto-refresh master data every 30 seconds
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _loadMasterData(),
    );

    // Listeners for real-time price calculation
    _rQtyController.addListener(() => setState(() => _calculateTotalPrice()));
    _lQtyController.addListener(() => setState(() => _calculateTotalPrice()));
    _rEyePriceController.addListener(() => setState(() => _calculateTotalPrice()));
    _lEyePriceController.addListener(() => setState(() => _calculateTotalPrice()));
  }

  Future<void> _loadCurrentUserInfo() async {
    final auth = AuthService();
    final name = await auth.getUserName();
    
    // getUserId() now returns the real AccountId/Phone after my previous fix
    final mobile = await auth.getUserId() ?? '';
    
    final details = await auth.getUserDetails();
    final address = details['address'] ?? '';

    if (mounted) {
      setState(() {
        _currentUserName = name;
        _currentUserMobile = mobile;
        _currentUserAddress = address;
        // Show the customer name in the ordering-for label
        _currentUserDetailsText = name.isNotEmpty ? name : mobile;
        
        // Populate controllers for the payload logic
        // These will now contain the real Name and Phone, not the Hex ID
        _customerNameController.text = name;
        _mobileController.text = mobile;
        _addressController.text = address;
      });
    }
  }

  Future<void> _fetchNextOrderId() async {
     // Only fetch if adding new order
    if (_editingOrderId == null) {
      final nextId = await _orderService.fetchNextOrderId();
      if (mounted) {
        setState(() => _orderIdController.text = nextId);
      }
    }
  }

  Future<void> _fetchCustomerHistory(String? mobile, {String? name}) async {
    final searchMobile = mobile ?? _mobileController.text;
    final searchName = name ?? _customerNameController.text;
    
    if (searchMobile.isEmpty && searchName.isEmpty) return;
    
    debugPrint('📚 [History] Fetching for Mob: $searchMobile, Name: $searchName');
    
    try {
      final allOrders = await _orderService.fetchOrders();
      final history = allOrders.where((o) {
        final oMobile = o['mobile']?.toString() ?? '';
        final oCustomer = o['customer']?.toString().toLowerCase() ?? '';
        final targetName = searchName.toLowerCase();
        
        // Match by mobile (if provided and valid)
        bool mobileMatch = searchMobile.isNotEmpty && oMobile == searchMobile;
        
        // Match by name (case-insensitive)
        bool nameMatch = targetName.isNotEmpty && oCustomer.contains(targetName);
        
        return (mobileMatch || nameMatch) && o['status'] == 'Delivered';
      }).toList();
      
      setState(() {
        _customerHistory = history;
      });
      debugPrint('📚 [History] Result: ${history.length} records found');
    } catch (e) {
      debugPrint('❌ [History] Error fetching: $e');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
       // Format as DD-MM-YYYY
       final formatted = "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
       setState(() {
         _dateController.text = formatted;
       });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isDataLoaded) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is Map<String, dynamic>) {
        _populateForm(args);
      }
      _isDataLoaded = true;
    }
  }

  void _populateForm(Map<String, dynamic> order) {
    // If order['raw'] exists (from OrderService), use it. Otherwise try to use the flat map.
    final raw = order['raw'] ?? order;
    
    // Extract ID (assuming _id or id)
    // Extract ID (assuming _id or id)
    _editingOrderId = raw['_id']?.toString() ?? raw['id']?.toString();
    _orderIdController.text = raw['invoice']?.toString() ?? _editingOrderId ?? 'Unknown';
    
    // Set Date
    final billData = raw['billData'] ?? {};
    if (billData['date'] != null) {
       // Simple check if it's ISO
       try {
         final dt = DateTime.parse(billData['date']);
         _dateController.text = "${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}";
       } catch (_) {
         _dateController.text = billData['date'].toString();
       }
    }

    // 1. Party Data
    final partyData = raw['partyData'] ?? {};
    _customerNameController.text = partyData['partyAccount'] ?? order['customer'] ?? '';
    _mobileController.text = partyData['mobile'] ?? '';
    _addressController.text = partyData['address'] ?? '';

    // 2. Vendor (bookedBy might be name, not ID. We need ID for dropdown)
    // We'll try to match name if ID not found, but ideally we need vendorId.
    // If raw has 'vendorId', use it.
    if (raw['vendorId'] != null) {
      _selectedVendorId = raw['vendorId'].toString();
    } 

    // 3. Items & Eye Data
    final items = raw['items'];
    if (items != null && items is List && items.isNotEmpty) {
      // Assume first item determines the Item Type
      final firstItem = items[0];
      if (firstItem['itemId'] != null) {
        _selectedItemId = firstItem['itemId'].toString();
      }

      // Reset selection
      setState(() {
        _isRightSelected = false;
        _isLeftSelected = false;
      });

      for (var item in items) {
        final eye = item['eye'] ?? 'RL';
        
        if (eye == 'Right' || eye == 'RL' || eye == 'R') {
           setState(() => _isRightSelected = true);
           _rSphController.text = item['sph']?.toString() ?? '';
           _rCylController.text = item['cyl']?.toString() ?? '';
           _rAxisController.text = item['axis']?.toString() ?? '';
           _rAddController.text = item['add']?.toString() ?? '';
           _rQtyController.text = item['quantity']?.toString() ?? '1';
        }

        if (eye == 'Left' || eye == 'RL' || eye == 'L') {
           setState(() => _isLeftSelected = true);
           _lSphController.text = item['sph']?.toString() ?? '';
           _lCylController.text = item['cyl']?.toString() ?? '';
           _lAxisController.text = item['axis']?.toString() ?? '';
           _lAddController.text = item['add']?.toString() ?? '';
           _lQtyController.text = item['quantity']?.toString() ?? '1';
        }
      }
    }
  }

  Future<void> _loadMasterData() async {
    setState(() => _isLoadingMasterData = true);
    final vendors = await _masterDataService.fetchVendors();
    final items = await _masterDataService.fetchItems();

    if (mounted) {
      setState(() {
        _vendors = vendors;
        _items = items;
        _isLoadingMasterData = false;
      });
    }
  }

  bool _isSaving = false;
  bool _isSuccess = false;

  void _saveOrder() async {
    
    // 1. GLOBAL VALIDATION
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields (marked *)'), backgroundColor: Colors.red),
      );
      return;
    }

    // 2. TAB-SPECIFIC VALIDATION
    if (_tabController.index == 0) { // RX Mode
      if (_selectedItemId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Please select an Item (Product)'), backgroundColor: Colors.red),
        );
        return;
      }
      if (!_isRightSelected && !_isLeftSelected) {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Please select at least one eye (R or L)'), backgroundColor: Colors.red),
        );
        return;
      }
    } else if (_tabController.index == 1) { // Single Finish Mode
       bool hasPendingItem = (_selectedItemId != null && (_isRightSelected || _isLeftSelected));
       if (_singleFinishItems.isEmpty && !hasPendingItem) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Order list is empty. Please add items or select a product.'), backgroundColor: Colors.red),
         );
         return;
       }
    } else if (_tabController.index == 2) { // Bulk Mode
       if (_bulkItems.isEmpty) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Bulk list is empty. Please add items to the list.'), backgroundColor: Colors.red),
         );
         return;
       }
    }

    // If validation passes...
    setState(() => _isSaving = true);

    try {
      // Build items array with eye prescriptions
      List<Map<String, dynamic>> orderItems = [];

      // Add Right Eye Item
      if (_isRightSelected) {
        orderItems.add({
          'eye': 'R',
          'itemId': _selectedItemId,
          'itemName': _itemNameController.text,
          'sph': _rSphController.text,
          'cyl': _rCylController.text,
          'axis': _rAxisController.text,
          'add': _rAddController.text,
          'quantity': int.tryParse(_rQtyController.text) ?? 1,
          'price': _rEyePrice,
        });
      }

      // Add Left Eye Item
      if (_isLeftSelected) {
        orderItems.add({
          'eye': 'L',
          'itemId': _selectedItemId,
          'itemName': _itemNameController.text,
          'sph': _lSphController.text,
          'cyl': _lCylController.text,
          'axis': _lAxisController.text,
          'add': _lAddController.text,
          'quantity': int.tryParse(_lQtyController.text) ?? 1,
          'price': _lEyePrice,
        });
      }

      // Parse date to ISO format
      String isoDate = DateTime.now().toIso8601String();
      if (_dateController.text.isNotEmpty) {
        try {
           final parts = _dateController.text.split('-');
           if (parts.length == 3) {
             final dt = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
             isoDate = "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
           }
        } catch (_) {}
      }

      // Construct items for Sale Order
      List<Map<String, dynamic>> saleItems = [];
      
      void addSaleItem(String eye, String sph, String cyl, String axis, String add, String qtyStr, double price) {
        int qty = int.tryParse(qtyStr) ?? 1;
        double total = price * qty;
        
        double sphNum = double.tryParse(sph) ?? 0;
        double cylNum = double.tryParse(cyl) ?? 0;
        double axisNum = double.tryParse(axis) ?? 0;
        double addNum = double.tryParse(add) ?? 0;
        
        saleItems.add({
          "barcode": "",
          "itemName": _itemNameController.text,
          "unit": "",
          "dia": "",
          "eye": eye,
          "sph": sphNum,
          "cyl": cylNum,
          "axis": axisNum,
          "add": addNum,
          "qty": qty,
          "purchasePrice": 0,
          "salePrice": price,
          "discount": 0,
          "totalAmount": total,
          "sellPrice": 0,
          "combinationId": _selectedItemId ?? "6970852e152a18a6ad847335",
        });
      }
      
      if (_tabController.index == 2) {
        // BULK MODE
        for (var item in _bulkItems) {
          saleItems.add(item);
        }
      } else if (_tabController.index == 1) {
        // SINGLE FINISH MODE
        for (var item in _singleFinishItems) {
          // Transform item to match backend schema
          saleItems.add({
            "barcode": "",
            "itemName": item['itemName'] ?? '',
            "unit": "",
            "dia": "",
            "eye": item['eye'] ?? '',
            "sph": double.tryParse(item['sph']?.toString() ?? '0') ?? 0,
            "cyl": double.tryParse(item['cyl']?.toString() ?? '0') ?? 0,
            "axis": double.tryParse(item['axis']?.toString() ?? '0') ?? 0,
            "add": double.tryParse(item['add']?.toString() ?? '0') ?? 0,
            "qty": (item['qty'] is int) ? item['qty'] : (double.tryParse(item['qty']?.toString() ?? '1') ?? 1).toInt(),
            "purchasePrice": 0,
            "salePrice": item['salePrice'] ?? 0,
            "discount": 0,
            "totalAmount": item['totalAmount'] ?? 0,
            "sellPrice": 0,
            "combinationId": item['itemId'] ?? _selectedItemId ?? "",
          });
        }
         // Fallback: If list empty, try adding current form item
        if (_singleFinishItems.isEmpty) {
           if (_isRightSelected) {
             addSaleItem('R', _rSphController.text, _rCylController.text, _rAxisController.text, _rAddController.text, _rQtyController.text, _rEyePrice);
           }
           if (_isLeftSelected) {
              addSaleItem('L', _lSphController.text, _lCylController.text, _lAxisController.text, _lAddController.text, _lQtyController.text, _lEyePrice);
           }
        }
      } else {
        // RX Mode
        if (_isRightSelected) {
          addSaleItem('R', _rSphController.text, _rCylController.text, _rAxisController.text, _rAddController.text, _rQtyController.text, _rEyePrice);
        }
        if (_isLeftSelected) {
           addSaleItem('L', _lSphController.text, _lCylController.text, _lAxisController.text, _lAddController.text, _lQtyController.text, _lEyePrice);
        }
      }

      // Calculate Totals
      double totalAmt = _totalPrice;
      if (_tabController.index == 2) {
         // Recalculate total for Bulk just in case
         totalAmt = _bulkItems.fold(0, (sum, item) => sum + (double.parse(item['totalAmount'].toString())));
      } else if (_tabController.index == 1) {
          totalAmt = _singleFinishItems.fold(0, (sum, item) => sum + (double.parse(item['totalAmount'].toString())));
           if (_singleFinishItems.isEmpty) totalAmt = _totalPrice; // fallback
      }
      
      double netAmt = totalAmt;

      // EDIT MODE LOGIC
      if (_editingOrderId != null) {
          if (_tabController.index == 0) {
             // RX - Not supported yet
             throw Exception('Editing RX orders is not supported yet.');
          }
          
          final payload = {
              "customerId": _currentUserMobile, 
              "items": saleItems 
          };
          
          await _orderService.editLensSaleOrder(_editingOrderId!, payload);
          
          if (mounted) {
            setState(() { _isSaving = false; _isSuccess = true; });
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order Updated Successfully!'), backgroundColor: Colors.green));
            await Future.delayed(const Duration(milliseconds: 1000));
            if (mounted) Navigator.pop(context, true);
          }
          return;
      }

      // Get Customer ID
      final userId = await AuthService().getUserId();
      if (userId == null && !AppConfig.useMockData) {
        throw Exception('User ID not found session expired.');
      }

      // Generate unique bill number using timestamp
      final uniqueBillNo = DateTime.now().millisecondsSinceEpoch.toString();

      // Construct payload
      final payload = {
          'billData': {
             'billSeries': _billSeriesController.text.isNotEmpty ? _billSeriesController.text : 'ORD_26',
             'billNo': uniqueBillNo,  // Always use unique timestamp
             'date': formatDateForApi(_dateController.text),
             'billType': 'GST 5%',
             'godown': 'Members',
             'bookedBy': 'App',
             'bankAccount': '',
          },
          'partyData': {
             'partyAccount': _customerNameController.text.isNotEmpty 
                 ? _customerNameController.text 
                 : 'Unnamed Customer',
             'address': _addressController.text,
             'contactNumber': _mobileController.text,
             'stateCode': 'Maharashtra',
             'creditLimit': 10000,
             'CurrentBalance': {'amount': 0, 'type': 'Dr'},
          },
          'summary': {
             'totalQty': saleItems.fold(0, (sum, item) => sum + (double.tryParse(item['qty'].toString()) ?? 0).toInt()),
             'totalAmount': netAmt,
          },
          'items': saleItems,
          'taxes': [{'taxName': 'CGST', 'type': 'Additive', 'percentage': 2.5, 'amount': 0}],
          'grossAmount': netAmt,
          'subtotal': netAmt,
             'taxesAmount': 0,
           'netAmount': netAmt,
           'paidAmount': double.tryParse(_advancePaidController.text) ?? 0.0,
           'dueAmount': netAmt - (double.tryParse(_advancePaidController.text) ?? 0.0),
           'remark': _remarksController.text,
           'status': 'Pending',
           'userId': userId,
           'orderType': _tabController.index == 0 ? 'RX' : (_tabController.index == 1 ? 'Single Finish' : 'Bulk'),
      };
      
      // Save Customer if enabled
      if (_shouldSaveCustomer) {
        final newCustomer = await _customerService.saveCustomer({
          'name': _customerNameController.text,
          'mobile': _mobileController.text,
          'address': _addressController.text,
          'dob': _dobController.text,
        });
        if (newCustomer != null && newCustomer['_id'] != null) {
          _selectedCustomerId = newCustomer['_id'].toString();
        }
      }

      // API Call
      dynamic result;
      if (_tabController.index == 0) {
        result = await _orderService.createRxOrder(payload);
      } else {
        result = await _orderService.createOrder(payload);
      }

      if (mounted) {
        setState(() {
          _isSaving = false;
          _isSuccess = true;
        });
        
        // Show Payment Modal
        _showPaymentModal(netAmt, result?['data']?['_id'] ?? result?['data']?['id'] ?? uniqueBillNo);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save order: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showPaymentModal(double totalAmount, String orderId) {
    double paidAmount = totalAmount;
    bool sendWhatsAppReminder = false;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            top: 24, left: 24, right: 24
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              const Text('PAYMENT DETAILS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
              const SizedBox(height: 8),
              Text('Order ID: $orderId', style: const TextStyle(color: Colors.grey, fontSize: 13)),
              const Divider(height: 32),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Bill:', style: TextStyle(fontSize: 16)),
                  Text('₹${totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 20),
              
              const Text('Amount Received:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                onChanged: (v) {
                  setModalState(() {
                    paidAmount = double.tryParse(v) ?? 0;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              if (paidAmount < totalAmount) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Balance Due: ₹${(totalAmount - paidAmount).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                            const Text('Mark as partial payment', style: TextStyle(fontSize: 12, color: Colors.orange)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Send WhatsApp Payment Reminder?', style: TextStyle(fontSize: 13)),
                  subtitle: const Text('Instantly notify customer of balance', style: TextStyle(fontSize: 11)),
                  value: sendWhatsAppReminder,
                  onChanged: (v) => setModalState(() => sendWhatsAppReminder = v),
                  activeColor: Colors.green,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
              
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    if (paidAmount > 0) {
                      // 1. Record the Receipt Voucher (for Accounting/Reports)
                      final success = await _collectionService.recordPayment(
                        orderId: orderId,
                        customerName: _customerNameController.text,
                        accountId: _selectedCustomerId, // Passing the linked ID
                        amount: paidAmount,
                        date: _dateController.text,
                      );
                      
                      if (!success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Order saved, but Payment Record failed! Please check your connection or Log Out and Log In.'), backgroundColor: Colors.orange)
                        );
                      }
                      
                      // 2. Update the SaleOrder's paidAmount (for Order Status)
                      await _orderService.updateOrderPayment(orderId, paidAmount, isRx: _tabController.index == 0);
                    }
                    _resetForm();
                    Navigator.pop(ctx); // Close the payment modal only
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order & Processed!'), backgroundColor: Colors.green));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('COMPLETE TRANSACTION', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController.dispose();
    _customerNameController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    _remarksController.dispose();
    _dateController.dispose();
    _deliveryDateController.dispose();
    _orderIdController.dispose();
    _itemNameController.dispose();
    _mainCategoryController.dispose();
    _subCategoryController.dispose();
    _rEyePriceController.dispose();
    _lEyePriceController.dispose();
    _rSphController.dispose();
    _rCylController.dispose();
    _rAxisController.dispose();
    _rAddController.dispose();
    _rQtyController.dispose();
    _lSphController.dispose();
    _lCylController.dispose();
    _lAxisController.dispose();
    _lAddController.dispose();
    _lQtyController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    
    // Reset Text Controllers
    _customerNameController.clear();
    _mobileController.clear();
    _addressController.clear();
    _remarksController.clear();
    _mainCategoryController.clear();
    _subCategoryController.clear();
    _itemNameController.clear();
    _dobController.clear();
    _fetchNextOrderId();
    
    // Reset Power Controllers
    _rSphController.clear();
    _rCylController.clear();
    _rAxisController.clear();
    _rAddController.clear();
    _rQtyController.text = '1'; // Default Qty
    
    _lSphController.clear();
    _lCylController.clear();
    _lAxisController.clear();
    _lAddController.clear();
    _lQtyController.text = '1'; // Default Qty
    
    // Reset specific fields with defaults
    // Dynamic Financial Year for Bill Series
    final now = DateTime.now();
    final startYear = (now.month >= 4) ? now.year : now.year - 1;
    final endYear = startYear + 1;
    _billSeriesController.text = 'ORD_${startYear.toString().substring(2)}-${endYear.toString().substring(2)}';
    _dateController.text = DateTime.now().toString().split(' ')[0];
    _deliveryDateController.text = DateTime.now().add(const Duration(days: 7)).toString().split(' ')[0];
    
    // Clear State Variables
    setState(() {
      _bulkItems.clear();
      _singleFinishItems.clear();
      _isRightSelected = true;
      _isLeftSelected = true;
      _selectedVendorId = null;
      _selectedItemId = null;
      _rEyePrice = 0.0;
      _lEyePrice = 0.0;
      _rEyePriceController.text = '0.00';
      _lEyePriceController.text = '0.00';
      _totalPrice = 0.0;
      _selectedItem = null;
      _shouldSaveCustomer = true;
    });

    // Clear dynamic controllers
    for (var controller in _extraTextControllers.values) {
      controller.clear();
    }
    _extraDropdownValues.clear();
  }

  void _openLensPowerMatrix() {
    if (_selectedItemId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an item first')),
      );
      return;
    }

    final selectedItemData = _items.firstWhere(
      (item) => (item['_id'] ?? item['id']) == _selectedItemId,
      orElse: () => {},
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LensPowerMatrixDialog(
        selectedItem: selectedItemData,
        onAddItems: (newItems) {
          setState(() {
            if (_tabController.index == 1) {
              // Single Finish Tab
              _singleFinishItems.addAll(newItems);
            } else {
              // Bulk Tab
              _bulkItems.addAll(newItems);
            }
            _calculateTotalPrice();
          });
        },
      ),
    );
  }

  // Helper to safely get/create a controller
  TextEditingController _getController(String key, {String? initialValue}) {
    if (_extraTextControllers.containsKey(key)) return _extraTextControllers[key]!;
    
    // Mapping for standard fields
    switch (key) {
      case 'advRemark': return _remarksController;
      case 'itemName': return _itemNameController;
      default:
        _extraTextControllers[key] = TextEditingController(text: initialValue);
        return _extraTextControllers[key]!;
    }
  }

  // --- Camera & Voice Logic ---

  void _toggleFab() {
    setState(() => _isFabExpanded = !_isFabExpanded);
  }

  Future<void> _scanOrder() async {
    setState(() => _isFabExpanded = false);
    
    // Request Camera Permission
    final status = await Permission.camera.request();
    if (status.isDenied) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Camera permission denied')));
       return;
    }

    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo == null) return;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Processing Image...')));
    }

    try {
      final inputImage = InputImage.fromFile(File(photo.path));
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      
      await textRecognizer.close();
      
      _populateFromText(recognizedText.text);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order data populated from image!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error scanning: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _listenVoice() async {
    setState(() => _isFabExpanded = false);

    // Request Microphone Permission
    final status = await Permission.microphone.request();
    if (status.isDenied) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Microphone permission denied')));
       return;
    }

    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'notListening' && _isListening) {
           setState(() => _isListening = false);
        }
      },
      onError: (errorNotification) {
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Voice Error: ${errorNotification.errorMsg}')));
         setState(() => _isListening = false);
      },
    );

    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            setState(() => _isListening = false);
            // Process the text
            _populateFromText(result.recognizedWords);
             if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Processed: "${result.recognizedWords}"'), backgroundColor: Colors.green));
            }
          }
        },
        localeId: 'en_IN', // Default to Indian English if available
        cancelOnError: true,
      );
      
      // Show bottom sheet to indicate listening
      if (mounted) {
        showModalBottomSheet(
          context: context,
          builder: (ctx) => Container(
            padding: const EdgeInsets.all(20),
            height: 250,
            child: Column(
              children: [
                const Icon(Icons.mic, size: 50, color: Colors.blueAccent),
                const SizedBox(height: 15),
                const Text('Listening...', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const Text('Say: "Right SPH -2.5 CYL -0.5"', style: TextStyle(color: Colors.grey, fontSize: 16)),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    _speech.stop();
                    Navigator.pop(ctx);
                  }, 
                  child: const Text('Cancel', style: TextStyle(color: Colors.red))
                )
              ],
            ),
          )
        ).whenComplete(() {
           _speech.stop();
           setState(() => _isListening = false);
        });
      }
    } else {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Speech recognition not available')));
    }
  }
  
  void _populateFromText(String rawText) {
    String text = rawText.toLowerCase().replaceAll('\n', ' ');
    debugPrint("Parsing Text: $text");
    
    // Regex Helpers
    // Match numbers with optional sign and decimals: -2.50, +1.00, 0.5
    final numberPattern = RegExp(r'[-+]?\d*\.?\d+'); 

    // Helper to find value AFTER a keyword
    String? extractValue(List<String> keywords, String input) {
      for (var keyword in keywords) {
        int index = input.indexOf(keyword);
        if (index != -1) {
          // Look ahead for a number
          String substring = input.substring(index + keyword.length);
          Match? match = numberPattern.firstMatch(substring);
          if (match != null) {
            // Check distance. If number is too far (e.g. > 15 chars), ignore
            // But for detailed texts it might be further. Let's keep it loose for now (20 chars).
            if (match.start < 25) {
               return match.group(0);
            }
          }
        }
      }
      return null;
    }

    // Keywords
    final rKeywords = ['right', 'od', 're', 'r ']; 
    final lKeywords = ['left', 'os', 'le', 'l '];
    
    final sphKeywords = ['sph', 'spherical', 'power', 'ds', 's '];
    final cylKeywords = ['cyl', 'cylinder', 'dc', 'c '];
    final axisKeywords = ['axis', 'ax', 'x ', 'a '];
    final addKeywords = ['add', 'addition', 'near'];

    // Split logic
    String rText = text;
    String lText = text;
    bool isSplit = false;
    
    int rIndex = -1;
    int lIndex = -1;
    
    // Find positions
    for (var k in rKeywords) { int i = text.indexOf(k); if(i!=-1) { rIndex = i; break; } }
    for (var k in lKeywords) { int i = text.indexOf(k); if(i!=-1) { lIndex = i; break; } }

    if (rIndex != -1 && lIndex != -1) {
      isSplit = true;
       if (rIndex < lIndex) {
         rText = text.substring(rIndex, lIndex);
         lText = text.substring(lIndex);
       } else {
         lText = text.substring(lIndex, rIndex);
         rText = text.substring(rIndex);
       }
    }

    // --- Expanded Parsing Logic ---
    
    // 1. Mobile Number (10 digits, starting with 6-9 usually in India, but let's be broad)
    // Look for pattern like "9876543210" or "+91 9876543210"
    final mobilePattern = RegExp(r'(?:(?:\+|0{0,2})91(\s*[\-]\s*)?|[0]?)?[6789]\d{9}');
    final mobileMatch = mobilePattern.firstMatch(rawText);
    if (mobileMatch != null) {
      String mob = mobileMatch.group(0)!.replaceAll(RegExp(r'\D'), ''); // Remove non-digits
      if (mob.length > 10) mob = mob.substring(mob.length - 10); // Keep last 10
      _mobileController.text = mob;
    }

    // 2. Customer Name
    // Look for lines starting with "Name:", "Patient:", "Mr.", "Mrs."
    final namePattern = RegExp(r'(?:name|patient|mr|mrs|ms)\.?\s*[:\-]?\s*([a-zA-Z\s]+)', caseSensitive: false);
    final nameMatch = namePattern.firstMatch(rawText);
    if (nameMatch != null) {
      _customerNameController.text = nameMatch.group(1)?.trim() ?? '';
    }

    // 3. Remarks / Notes
    final remarkPattern = RegExp(r'(?:note|remark|instruction)s?\.?\s*[:\-]?\s*(.*)', caseSensitive: false);
    final remarkMatch = remarkPattern.firstMatch(rawText);
    if (remarkMatch != null) {
      _remarksController.text = remarkMatch.group(1)?.trim() ?? '';
    }

    // 4. PD (Pupillary Distance) -> Update Advanced Options
    final pdPattern = RegExp(r'(?:pd|pupillary|distance)\.?\s*[:\-]?\s*(\d{2}(\.\d)?)', caseSensitive: false);
    final pdMatch = pdPattern.firstMatch(rawText);
    if (pdMatch != null) {
       // We map PD to 'dbl' (Distance Between Lenses) or 'prismRemark' as a fallback since there isn't a direct PD field in basic form
       // Let's put it in "Adv Remark" or "DBL" if it looks like a DBL value. 
       // Only valid DBLs are usually 14-24, PDs are 50-70. 
       // So we'll append to remarks or advanced remarks.
       String existing = _getController('advRemark').text;
       _getController('advRemark').text = existing.isEmpty ? "PD: ${pdMatch.group(1)}" : "$existing, PD: ${pdMatch.group(1)}";
    }

    setState(() {
       // Auto-select eyes based on detection
       if (isSplit) {
         _isRightSelected = true;
         _isLeftSelected = true;
       } else {
          if (rIndex != -1 && lIndex == -1) {
             _isRightSelected = true;
             _isLeftSelected = false;
          } else if (lIndex != -1 && rIndex == -1) {
             _isRightSelected = false;
             _isLeftSelected = true;
          }
       }
       
       // Populate RIGHT
       if (_isRightSelected) {
          String? sph = extractValue(sphKeywords, rText);
          if (sph != null) _rSphController.text = sph;
          
          String? cyl = extractValue(cylKeywords, rText);
          if (cyl != null) _rCylController.text = cyl;
          
          String? axis = extractValue(axisKeywords, rText);
          if (axis != null) _rAxisController.text = axis;
          
          String? add = extractValue(addKeywords, rText);
          if (add != null) _rAddController.text = add;
       }

       // Populate LEFT
       if (_isLeftSelected) {
          String? sph = extractValue(sphKeywords, lText);
          if (sph != null) _lSphController.text = sph;
          
          String? cyl = extractValue(cylKeywords, lText);
          if (cyl != null) _lCylController.text = cyl;
          
          String? axis = extractValue(axisKeywords, lText);
          if (axis != null) _lAxisController.text = axis;
          
          String? add = extractValue(addKeywords, lText);
          if (add != null) _lAddController.text = add;
       }
       
       _calculateTotalPrice(); 
    });
  }





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: widget.onBack != null 
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              ) 
            : (Navigator.of(context).canPop() ? const BackButton() : null),
        title: Text(_editingOrderId != null ? 'Edit Order' : 'New Job Card'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: null,
      body: Column(
      children: [
        // Compact Header: TabBar + Refresh Action
        Container(
          color: const Color(0xFF1A237E), // Match Dashboard AppBar
          child: Row(
            children: [
              // Tabs take available width
              Expanded(
                child: TabBar(
                  controller: _tabController,
                  isScrollable: false, // Equal space distribution
                  labelColor: const Color(0xFFD4AF37), // Gold
                  unselectedLabelColor: Colors.white70,
                  indicatorWeight: 3,
                  indicatorColor: const Color(0xFFD4AF37),
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.medical_services_outlined, size: 20),
                      text: 'RX',
                    ),
                    Tab(
                      icon: Icon(Icons.check_circle_outline, size: 20),
                      text: 'Single Finish',
                    ),
                    Tab(
                      icon: Icon(Icons.inventory_2_outlined, size: 20),
                      text: 'Bulk',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Main Content Area
        Expanded(
          child: Form(
            key: _formKey,
            child: TabBarView(
              controller: _tabController,
              children: [
                RefreshIndicator(
                  onRefresh: _loadMasterData,
                  child: _buildRXForm(),
                ),
                RefreshIndicator(
                  onRefresh: _loadMasterData,
                  child: _buildSingleFinishForm(),
                ),
                RefreshIndicator(
                  onRefresh: _loadMasterData,
                  child: _buildBulkForm(),
                ),
              ],
            ),
          ),
        ),
      ],
      ),
    );
  }

  void _showBookingInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Booking Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _billSeriesController,
              decoration: const InputDecoration(
                labelText: 'Bill Series', 
                isDense: true, 
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color(0xFFF5F5F5),
              ),
              readOnly: true,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _orderIdController,
              decoration: const InputDecoration(
                labelText: 'Order ID', 
                isDense: true, 
                filled: true, 
                fillColor: Color(0xFFF5F5F5),
                border: OutlineInputBorder()
              ),
              readOnly: true,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _dateController,
              decoration: const InputDecoration(
                labelText: 'Date',
                suffixIcon: Icon(Icons.calendar_today, color: Colors.grey),
                isDense: true,
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color(0xFFF5F5F5),
              ),
              readOnly: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildRXForm() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 800;
        final horizontalPadding = isWideScreen ? 24.0 : 16.0;
        
        Widget formContent = SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16.0),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step 0: Header with Booking Info Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionTitle('RX Order'),
              IconButton(
                icon: const Icon(Icons.info_outline, color: Colors.blue),
                onPressed: _showBookingInfoDialog,
                tooltip: 'Booking Details',
              ),
            ],
          ),

          // Step 1: Account Context Info
          _buildCustomerInfoSection(),
          const SizedBox(height: 16),
          _buildVendorAndCategorySection(),
          const SizedBox(height: 16),

          // Step 2: Product Selection
          if (_selectedCategory != 'Both') ...[
            _buildSectionTitle(_selectedCategory == 'Frame' ? 'Frame Details' : 'Lens & Power Details'),
            Card(
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Product Selection', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Item Name *',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      initialValue: _selectedItemId,
                      items: _items.where((i) {
                        final cat = (i['mainCategory'] ?? '').toString().toLowerCase();
                        final isFr = i['isFrame'] == true || cat.contains('frame');
                        if (_selectedCategory == 'Lens') return !isFr && cat.contains('lens') && !cat.contains('contact');
                        if (_selectedCategory == 'Frame') return isFr;
                        if (_selectedCategory == 'Contact Lens') return cat.contains('contact');
                        if (_selectedCategory == 'Solutions') return cat.contains('solution');
                        return true;
                      }).map((i) {
                        return DropdownMenuItem(
                          value: i['id']?.toString() ?? i['_id']?.toString(),
                          child: Text(i['itemName'] ?? 'Unknown Item', style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (v) {
                        setState(() => _selectedItemId = v);
                        // Find item and update prices
                        try {
                          final item = _items.firstWhere(
                            (i) => (i['id']?.toString() ?? i['_id']?.toString()) == v,
                            orElse: () => {},
                          );
                          if (item.isNotEmpty) _updatePricesFromItem(item);
                        } catch (e) {
                           // ignore
                        }
                      },
                    ),
                    if (_selectedItem != null && _selectedItemId != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[100]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.sell, size: 16, color: Colors.blue),
                            const SizedBox(width: 8),
                            const Text('Item Price: ', style: TextStyle(fontSize: 12, color: Colors.black54)),
                            Builder(
                              builder: (context) {
                                final unitPrice = double.tryParse(_selectedItem!['salePrice']?.toString() ?? '0') ?? 0.0;
                                final qty = (_isRightSelected ? (int.tryParse(_rQtyController.text) ?? 1) : 0) + 
                                            (_isLeftSelected ? (int.tryParse(_lQtyController.text) ?? 1) : 0);
                                return Text(
                                  '₹${(unitPrice * qty).toStringAsFixed(0)}${qty > 1 ? ' (₹${unitPrice.toStringAsFixed(0)} x $qty)' : ''}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 14),
                                );
                              }
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    // --- Advanced Parameters (Hidden by default) ---
                    const SizedBox(height: 8),
                    Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        title: const Text(
                          'Advanced Lens Options', 
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: const EdgeInsets.only(bottom: 8),
                        children: [
                          // Row A: Base, Prism, Index
                           ResponsiveRow(
                            children: [
                              _buildDropdownField('base', 'Base', const ['2', '4', '6', '8']),
                              _buildTextField('prismRemark', 'Prism'),
                              _buildDropdownField('index', 'Index', const ['1.5', '1.56', '1.6', '1.67', '1.74']),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Row B: Tint, Upgrade, Coating
                          ResponsiveRow(
                            children: [
                              _buildDropdownField('tint', 'Tint', const ['Hard', 'Soft']),
                              _buildDropdownField('upgrade', 'Upgrade', const ['Yes', 'No']),
                              _buildDropdownField('mirrorCoating', 'Mirror/Coating', const ['Blue', 'Gold', 'Silver']),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Row C: Fitting & Sizes
                          ResponsiveRow(
                            children: [
                               _buildDropdownField('fitting', 'Fitting', const ['Regular', 'Special']),
                               _buildTextField('aSize', 'A Size'),
                               _buildTextField('bSize', 'B Size'),
                               _buildTextField('dbl', 'DBL'),
                            ],
                          ),
                           const SizedBox(height: 8),
                          _buildTextField('advRemark', 'Remark / Special Instructions'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Step 3: Power Details (The Table)
          _buildEyeGrid(),
          const SizedBox(height: 32),

          // --- Pricing ---
          _buildPricingAndActions(buttonLabel: _editingOrderId != null ? 'Update Order' : 'Order Save', onButtonPressed: _saveOrder),
          const SizedBox(height: 32),
        ],
      ),
    );
        
        // Center and constrain width on wide screens
        if (isWideScreen) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: formContent,
            ),
          );
        }
        return formContent;
      },
    );
  }

  Widget _buildEyeGrid({bool showAdd = true, bool isFrameOnly = false}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Expanded(
                flex: 2,
                child: Text(
                  'EYE',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black54),
                ),
              ),
              const SizedBox(width: 2),
              if (_selectedCategory != 'Frame' && _selectedCategory != 'Solutions' && !isFrameOnly) ...[
                const Expanded(flex: 3, child: Center(child: Text('SPH', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black87)))),
                const SizedBox(width: 2),
                const Expanded(flex: 3, child: Center(child: Text('CYL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black87)))),
                const SizedBox(width: 2),
                const Expanded(flex: 3, child: Center(child: Text('AXIS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black87)))),
                const SizedBox(width: 2),
                if (showAdd) ...[
                  const Expanded(flex: 3, child: Center(child: Text('ADD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black87)))),
                  const SizedBox(width: 2),
                ],
              ],
              const Expanded(flex: 2, child: Text('QTY', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black87))),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _buildEyeRow(
          eye: 'R', 
          isSelected: isFrameOnly ? _isRightFrameSelected : _isRightSelected, 
          onChanged: (val) => setState(() {
            if (isFrameOnly) _isRightFrameSelected = val!; else _isRightSelected = val!;
            _calculateTotalPrice();
          }),
          sph: (isFrameOnly || _selectedCategory == 'Solutions' || _selectedCategory == 'Frame') ? null : _rSphController,
          cyl: (isFrameOnly || _selectedCategory == 'Solutions' || _selectedCategory == 'Frame') ? null : _rCylController,
          axis: (isFrameOnly || _selectedCategory == 'Solutions' || _selectedCategory == 'Frame') ? null : _rAxisController,
          add: (isFrameOnly || _selectedCategory == 'Solutions' || _selectedCategory == 'Frame' || !showAdd) ? null : _rAddController,
          qty: isFrameOnly ? _rFrameQtyController : _rQtyController,
        ),
        const SizedBox(height: 8),
        _buildEyeRow(
          eye: 'L', 
          isSelected: isFrameOnly ? _isLeftFrameSelected : _isLeftSelected, 
          onChanged: (val) => setState(() {
            if (isFrameOnly) _isLeftFrameSelected = val!; else _isLeftSelected = val!;
            _calculateTotalPrice();
          }),
          sph: (isFrameOnly || _selectedCategory == 'Solutions' || _selectedCategory == 'Frame') ? null : _lSphController,
          cyl: (isFrameOnly || _selectedCategory == 'Solutions' || _selectedCategory == 'Frame') ? null : _lCylController,
          axis: (isFrameOnly || _selectedCategory == 'Solutions' || _selectedCategory == 'Frame') ? null : _lAxisController,
          add: (isFrameOnly || _selectedCategory == 'Solutions' || _selectedCategory == 'Frame' || !showAdd) ? null : _lAddController,
          qty: isFrameOnly ? _lFrameQtyController : _lQtyController,
        ),
      ],
    );
  }

  Widget _buildEyeRow({
    required String eye,
    required bool isSelected,
    required ValueChanged<bool?> onChanged,
    TextEditingController? sph,
    TextEditingController? cyl,
    TextEditingController? axis,
    TextEditingController? add,
    required TextEditingController qty,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue[50]!.withValues(alpha: 0.5) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Transform.scale(
                    scale: 0.7,
                    child: Checkbox(
                      value: isSelected,
                      activeColor: const Color(0xFF1A237E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      onChanged: onChanged,
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                Text(eye, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 2),
          if (sph != null) ...[
            Expanded(flex: 3, child: _buildTableInput(sph)),
            const SizedBox(width: 2),
            Expanded(flex: 3, child: _buildTableInput(cyl!)),
            const SizedBox(width: 2),
            Expanded(flex: 3, child: _buildTableInput(axis!)),
            const SizedBox(width: 2),
            if (add != null) ...[
              Expanded(flex: 3, child: _buildTableInput(add)),
              const SizedBox(width: 2),
            ],
          ],
          Expanded(flex: 2, child: _buildTableInput(qty, isQty: true)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return TextFormField(
      initialValue: value,
      readOnly: true,
      enabled: false,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey[200],
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(
             borderRadius: BorderRadius.circular(4),
             borderSide: BorderSide.none
        ),
      ),
      style: const TextStyle(fontSize: 13, color: Colors.black87),
    );
  }

  Widget _buildDropdownField(String key, String label, List<String> items) {
    return DropdownButtonFormField<String>(
      initialValue: _extraDropdownValues[key],
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey[50], // Visible background
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
           borderRadius: BorderRadius.circular(30),
           borderSide: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
      onChanged: (v) {
        setState(() {
          _extraDropdownValues[key] = v;
        });
      },
    );
  }

  Widget _buildTextField(String key, String label) {
    return TextFormField(
      controller: _getController(key),
      decoration: InputDecoration(
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildCompactInput(TextEditingController controller, String hint) {
    return SizedBox(
      height: 40,
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 0,
          ),
        ),
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
      ),
    );
  }

  Widget _buildSingleFinishForm() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 800;
        final horizontalPadding = isWideScreen ? 24.0 : 16.0;
        
        Widget formContent = SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16.0),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step 0: Header with Booking Info Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionTitle('Single Finish Order'),
              IconButton(
                icon: const Icon(Icons.info_outline, color: Colors.blue),
                onPressed: _showBookingInfoDialog,
                tooltip: 'Booking Details',
              ),
            ],
          ),

          // Step 1: Account Context Info
          _buildCustomerInfoSection(),
          const SizedBox(height: 16),
          _buildVendorAndCategorySection(),
          const SizedBox(height: 16),

          // Step 2: Item Entry (Add New Item)
          _buildSectionTitle('Add Items'),
          Card(
            shape: RoundedRectangleBorder(
              side: BorderSide(color: Colors.blue.shade100, width: 1.5),
              borderRadius: BorderRadius.circular(24),
            ),
            color: Colors.blue[50]?.withValues(alpha: 0.3),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('1. Select Product', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Item Name *',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(),
                      isDense: true,
                      fillColor: Colors.white,
                      filled: true,
                    ),
                    initialValue: _selectedItemId,
                    items: _items.where((i) {
                      final cat = (i['mainCategory'] ?? '').toString().toLowerCase();
                      final isFr = i['isFrame'] == true || cat.contains('frame');
                      if (_selectedCategory == 'Lens') return !isFr && cat.contains('lens') && !cat.contains('contact');
                      if (_selectedCategory == 'Frame') return isFr;
                      if (_selectedCategory == 'Contact Lens') return cat.contains('contact');
                      if (_selectedCategory == 'Solutions') return cat.contains('solution');
                      return true;
                    }).map((i) {
                      return DropdownMenuItem(
                        value: i['id']?.toString() ?? i['_id']?.toString(),
                        child: Text(i['itemName'] ?? 'Unknown Item', style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (v) {
                       setState(() {
                         _selectedItemId = v;
                         // Also update the text controller for validation
                         try {
                           final item = _items.firstWhere(
                             (i) => (i['id']?.toString() ?? i['_id']?.toString()) == v,
                             orElse: () => {},
                           );
                           if (item.isNotEmpty) {
                             _itemNameController.text = item['itemName'] ?? item['name'] ?? '';
                             _updatePricesFromItem(item);
                           }
                         } catch (_) {}
                       });
                     },
                  ),
                  if (_selectedItem != null && _selectedItemId != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[100]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.sell, size: 16, color: Colors.blue),
                          const SizedBox(width: 8),
                          const Text('Item Price: ', style: TextStyle(fontSize: 12, color: Colors.black54)),
                          Builder(
                            builder: (context) {
                              final unitPrice = double.tryParse(_selectedItem!['salePrice']?.toString() ?? '0') ?? 0.0;
                              final qty = (_isRightSelected ? (int.tryParse(_rQtyController.text) ?? 1) : 0) + 
                                          (_isLeftSelected ? (int.tryParse(_lQtyController.text) ?? 1) : 0);
                              return Text(
                                '₹${(unitPrice * qty).toStringAsFixed(0)}${qty > 1 ? ' (₹${unitPrice.toStringAsFixed(0)} x $qty)' : ''}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 14),
                              );
                            }
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  
                  if (_selectedCategory != 'Solutions') ...[
                    Text(
                      (_selectedCategory == 'Frame') ? '2. Select Eye & Quantity' : '2. Enter Power', 
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)
                    ),
                    const SizedBox(height: 8),
                    _buildEyeGrid(showAdd: true),
                  ],
                  const SizedBox(height: 16),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
                      label: const Text('ADD TO LIST', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _addSingleFinishItemFromGrid,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Step 3: Added Items List
          if (_singleFinishItems.isNotEmpty) ...[
            _buildSectionTitle('Added Items (${_getGroupedItemCount()})'),
            ..._buildGroupedSingleFinishItems(),
          ],

          // Step 4: Summary & Save
          Card(
             color: Colors.blue[50],
             child: Padding(
               padding: const EdgeInsets.all(16.0),
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   const Text('Total Amount:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                   Text('₹${_totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                 ],
               ),
             ),
          ),
          const SizedBox(height: 16),
          
          _buildPricingAndActions(buttonLabel: _editingOrderId != null ? 'Update Order' : 'Save Order', onButtonPressed: _saveOrder),
          const SizedBox(height: 32),
          ],
          ),
        );
        
        // Center and constrain width on wide screens
        if (isWideScreen) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: formContent,
            ),
          );
        }
        return formContent;
      },
    );
  }

  Widget _buildBulkForm() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 800;
        final horizontalPadding = isWideScreen ? 24.0 : 16.0;

        Widget formContent = SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step 0: Header with Booking Info Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle('Bulk Order'),
                  IconButton(
                    icon: const Icon(Icons.info_outline, color: Colors.blue),
                    onPressed: _showBookingInfoDialog,
                    tooltip: 'Booking Details',
                  ),
                ],
              ),

              // Step 1: Account Context Info
              _buildCustomerInfoSection(),
              const SizedBox(height: 16),

              // Step 1.5: Vendor & Category
              _buildVendorAndCategorySection(),
              const SizedBox(height: 16),

              // Step 2: Bulk Item Selection & Entry Table
              _buildSectionTitle('Order Items'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      // Item Name Selection
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Item Name *',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        initialValue: _selectedItemId,
                        items: _items.where((i) {
                          final cat = (i['mainCategory'] ?? '').toString().toLowerCase();
                          final isFr = i['isFrame'] == true || cat.contains('frame');
                          if (_selectedCategory == 'Lens') return !isFr && cat.contains('lens') && !cat.contains('contact');
                          if (_selectedCategory == 'Frame') return isFr;
                          if (_selectedCategory == 'Contact Lens') return cat.contains('contact');
                          if (_selectedCategory == 'Solutions') return cat.contains('solution');
                          return true;
                        }).map((i) {
                          return DropdownMenuItem(
                            value: i['id']?.toString() ?? i['_id']?.toString(),
                            child: Text(i['itemName'] ?? 'Unknown Item', style: const TextStyle(fontSize: 13)),
                          );
                        }).toList(),
                        onChanged: (v) {
                          setState(() {
                            _selectedItemId = v;
                            try {
                              final item = _items.firstWhere(
                                (i) => (i['id']?.toString() ?? i['_id']?.toString()) == v,
                                orElse: () => {},
                              );
                              if (item.isNotEmpty) {
                                _itemNameController.text = item['itemName'] ?? item['name'] ?? '';
                                _updatePricesFromItem(item);
                              }
                            } catch (_) {}
                          });
                        },
                      ),
                      if (_selectedItem != null && _selectedItemId != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue[100]!),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.sell, size: 16, color: Colors.blue),
                              const SizedBox(width: 8),
                              const Text('Item Price: ', style: TextStyle(fontSize: 12, color: Colors.black54)),
                              Text(
                                '₹${_selectedItem!['salePrice']?.toString() ?? '0.00'}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Matrix Entry Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _openLensPowerMatrix,
                          icon: const Icon(Icons.grid_on, size: 20),
                          label: const Text('OPEN MATRIX ENTRY', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D1B2A), // Dark Blue
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Center(child: Text('Click above to add items via Matrix', style: TextStyle(color: Colors.grey, fontSize: 12))),
                      const SizedBox(height: 16),

                      // List of added items in table format
                      if (_bulkItems.isNotEmpty)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minWidth: 500), // Ensure minimum width
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildPowerTableHeader(),
                                const Divider(height: 1),
                                ..._bulkItems.map((item) => _buildAddedPowerRow(item)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Step 4: Summary & Save
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('₹${_totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _buildPricingAndActions(buttonLabel: _editingOrderId != null ? 'Update Order' : 'Save Order', onButtonPressed: _saveOrder),
              const SizedBox(height: 32),
            ],
          ),
        );

        //Center and constrain width on wide screens
        if (isWideScreen) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: formContent,
            ),
          );
        }
        return formContent;
      },
    );
  }



  void _addBulkMatrixItems(List<Map<String, dynamic>> newItems) {
    setState(() {
      _bulkItems.addAll(newItems);
      // Recalculate total price
      double addedAmount = newItems.fold(0, (sum, item) => sum + (double.tryParse(item['totalAmount'].toString()) ?? 0));
      _totalPrice += addedAmount;
    });
  }

  Widget _buildPowerTableHeader() {
    return Container(
      color: const Color(0xFFF9F5EB),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: const Row(
        children: [
          SizedBox(width: 50, child: Center(child: Text('EYE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)))),
          SizedBox(width: 50, child: Center(child: Text('SPH', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)))),
          SizedBox(width: 50, child: Center(child: Text('CYL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)))),
          SizedBox(width: 50, child: Center(child: Text('AXIS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)))),
          SizedBox(width: 50, child: Center(child: Text('ADD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)))),
          SizedBox(width: 50, child: Center(child: Text('QTY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)))),
          SizedBox(width: 80, child: Center(child: Text('PRICE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)))),
          SizedBox(width: 100, child: Center(child: Text('TTL AMT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)))),
        ],
      ),
    );
  }

  Widget _buildPowerEntryRow({required VoidCallback onAdd}) {
    double qty = double.tryParse(_rQtyController.text) ?? 1;
    double ttl = _rEyePrice * qty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const SizedBox(width: 50, child: Center(child: Text('BOTH', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)))),
          SizedBox(width: 50, child: _buildTableInput(_rSphController)),
          SizedBox(width: 50, child: _buildTableInput(_rCylController)),
          SizedBox(width: 50, child: _buildTableInput(_rAxisController)),
          SizedBox(width: 50, child: _buildTableInput(_rAddController)),
          SizedBox(width: 50, child: _buildTableInput(_rQtyController)),
          SizedBox(width: 60, child: Center(child: Text(_rEyePrice.toStringAsFixed(1), style: const TextStyle(fontSize: 11)))),
          SizedBox(width: 100, child: 
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(ttl.toStringAsFixed(1), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.blue, size: 24),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onAdd,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }





  // Helper: Get count of grouped items (R+L count as 1)
  int _getGroupedItemCount() {
    final grouped = _groupSingleFinishItems();
    return grouped.length;
  }

  // Helper: Group items by itemId (combine R and L of same item)
  List<Map<String, dynamic>> _groupSingleFinishItems() {
    final Map<String, Map<String, dynamic>> groups = {};
    
    for (var item in _singleFinishItems) {
      // Extract timestamp from key (e.g., "1234567890_R" -> "1234567890")
      final key = item['key'] as String;
      final timestamp = key.split('_')[0];
      
      if (!groups.containsKey(timestamp)) {
        groups[timestamp] = {
          'timestamp': timestamp,
          'itemName': item['itemName'],
          'eyes': <Map<String, dynamic>>[],
          'keys': <String>[],
        };
      }
      groups[timestamp]!['eyes'].add(item);
      groups[timestamp]!['keys'].add(item['key']);
    }
    
    return groups.values.toList();
  }

  // Helper: Build grouped item cards
  List<Widget> _buildGroupedSingleFinishItems() {
    final grouped = _groupSingleFinishItems();
    
    return grouped.map((group) {
      final eyes = group['eyes'] as List<Map<String, dynamic>>;
      final hasR = eyes.any((e) => e['eye'] == 'R');
      final hasL = eyes.any((e) => e['eye'] == 'L');
      final rData = eyes.firstWhere((e) => e['eye'] == 'R', orElse: () => {});
      final lData = eyes.firstWhere((e) => e['eye'] == 'L', orElse: () => {});
      
      final totalAmount = eyes.fold<double>(0, (sum, e) => sum + (e['totalAmount'] as double));
      
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Item name + Price + Delete
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      group['itemName'],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  Text(
                    '₹${totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                    onPressed: () {
                      setState(() {
                        // Calculate total amount to subtract
                        final amountToRemove = eyes.fold<double>(
                          0, 
                          (sum, e) => sum + (e['totalAmount'] as double),
                        );
                        _totalPrice -= amountToRemove;
                        
                        // Remove all items with matching keys
                        final keysToRemove = group['keys'] as List<String>;
                        _singleFinishItems.removeWhere((item) => keysToRemove.contains(item['key']));
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Eye details
              if (hasR) ...[
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.blue[100],
                      child: const Text('R', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'SPH:${rData['sph']} CYL:${rData['cyl']} AXIS:${rData['axis']} QTY:${rData['qty']}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                if (hasL) const SizedBox(height: 6),
              ],
              if (hasL) ...[
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.green[100],
                      child: const Text('L', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'SPH:${lData['sph']} CYL:${lData['cyl']} AXIS:${lData['axis']} QTY:${lData['qty']}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildTableInput(TextEditingController controller, {bool isQty = false}) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 2, offset: const Offset(0, 1)),
        ],
      ),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 10), // Centered vertically
          border: InputBorder.none, // Clean look, no internal border
          focusedBorder: OutlineInputBorder(
             borderSide: BorderSide(color: Color(0xFFD4AF37), width: 1.5), // Gold highlight on focus
             borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
        onChanged: (_) {
           if (!isQty) _calculateTotalPrice(); // Optimization: Only recalc if needed, but safe to call
           setState(() {});
        },
      ),
    );
  }

  void _addItemToList(List<Map<String, dynamic>> targetList) {
    if (_itemNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select Item Name first')));
      return;
    }
    setState(() {
      final qty = double.tryParse(_rQtyController.text) ?? 1;
      final price = _rEyePrice;
      targetList.add({
        "itemName": _itemNameController.text,
        "itemId": _selectedItemId,
        "eye": "BOTH",
        "sph": _rSphController.text,
        "cyl": _rCylController.text,
        "axis": _rAxisController.text,
        "add": _rAddController.text,
        "qty": qty,
        "salePrice": price,
        "totalAmount": price * qty,
        "key": DateTime.now().millisecondsSinceEpoch.toString(),
      });
      _totalPrice += price * qty;
      
      // Clear power fields for next entry
      _rSphController.clear();
      _rCylController.clear();
      _rAxisController.clear();
      _rAddController.clear();
      _rQtyController.text = '1';
    });
  }

  void _addBulkItem() => _addItemToList(_bulkItems);
  void _addSingleFinishItem() => _addItemToList(_singleFinishItems);

  void _addSingleFinishItemFromGrid() {
    debugPrint('🔍 [Debug] Add to List pressed. _selectedItemId=$_selectedItemId, _itemNameController.text="${_itemNameController.text}"');
    
    if (_selectedItemId == null || _selectedItemId!.isEmpty) {
      debugPrint('❌ [Debug] Validation failed: no item selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an item first')),
      );
      return;
    }
    
    // Get the selected item's name
    final selectedItem = _items.firstWhere(
      (i) => (i['id']?.toString() ?? i['_id']?.toString()) == _selectedItemId,
      orElse: () => {},
    );
    final itemName = selectedItem['itemName'] ?? selectedItem['name'] ?? 'Unknown Item';
    
    debugPrint('✅ [Debug] Item validated: $itemName');
    
    if (!_isRightSelected && !_isLeftSelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one eye (R or L)')),
      );
      return;
    }

    setState(() {
      // Generate single timestamp for this add action
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      // Add Right Eye item if selected
      if (_isRightSelected) {
        final qty = double.tryParse(_rQtyController.text) ?? 1;
        final price = _rEyePrice;
        _singleFinishItems.add({
          "itemName": itemName,  // Use validated item name
          "itemId": _selectedItemId,
          "eye": "R",
          "sph": _rSphController.text,
          "cyl": _rCylController.text,
          "axis": _rAxisController.text,
          "add": _rAddController.text,
          "qty": qty,
          "salePrice": price,
          "totalAmount": price * qty,
          "key": "${timestamp}_R",
        });
        _totalPrice += price * qty;
      }
      
      // Add Left Eye item if selected
      if (_isLeftSelected) {
        final qty = double.tryParse(_lQtyController.text) ?? 1;
        final price = _lEyePrice;
        _singleFinishItems.add({
          "itemName": itemName,  // Use validated item name
          "itemId": _selectedItemId,
          "eye": "L",
          "sph": _lSphController.text,
          "cyl": _lCylController.text,
          "axis": _lAxisController.text,
          "add": _lAddController.text,
          "qty": qty,
          "salePrice": price,
          "totalAmount": price * qty,
          "key": "${timestamp}_L",
        });
        _totalPrice += price * qty;
      }
      
      // Clear fields for next item
      _rSphController.clear();
      _rCylController.clear();
      _rAxisController.clear();
      _rAddController.clear();
      _rQtyController.text = '1';
      _lSphController.clear();
      _lCylController.clear();
      _lAxisController.clear();
      _lAddController.clear();
      _lQtyController.text = '1';
      _isRightSelected = true;
      _isLeftSelected = true;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Item added to order!'), backgroundColor: Colors.green),
    );
  }

  Widget _buildAddedPowerRow(Map<String, dynamic> item) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[200]!))),
      child: Row(
        children: [
          SizedBox(width: 50, child: Center(child: Text(item['eye'], style: const TextStyle(fontSize: 10)))),
          SizedBox(width: 50, child: Center(child: Text(item['sph'], style: const TextStyle(fontSize: 10)))),
          SizedBox(width: 50, child: Center(child: Text(item['cyl'], style: const TextStyle(fontSize: 10)))),
          SizedBox(width: 50, child: Center(child: Text(item['axis'], style: const TextStyle(fontSize: 10)))),
          SizedBox(width: 50, child: Center(child: Text(item['add'], style: const TextStyle(fontSize: 10)))),
          SizedBox(width: 50, child: Center(child: Text(item['qty'].toString(), style: const TextStyle(fontSize: 10)))),
          SizedBox(width: 60, child: Center(child: Text(item['salePrice'].toStringAsFixed(1), style: const TextStyle(fontSize: 10)))),
          SizedBox(width: 100, child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(item['totalAmount'].toStringAsFixed(1), style: const TextStyle(fontSize: 10)),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  setState(() {
                    _bulkItems.remove(item);
                    _totalPrice -= (double.tryParse(item['totalAmount'].toString()) ?? 0);
                  });
                },
              )
            ],
          )),
        ],
      ),
    );
  }

  Widget _buildBookingRightPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Booking & Customer Details'),
        Card(
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.blue.withValues(alpha: 0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                ResponsiveRow(
                  breakpoint: 400,
                  children: [
                    _buildBillSeriesField(),
                    _buildOrderIdField(),
                  ],
                ),
                const SizedBox(height: 8),
                ResponsiveRow(
                  breakpoint: 400,
                  children: [
                    _buildDateField(),
                    _buildDropdownField('sf_billType', 'Bill Type', const ['TAXFREE(L)']),
                  ],
                ),
                const SizedBox(height: 8),
                ResponsiveRow(
                  breakpoint: 400,
                  children: [
                    _buildDropdownField('sf_godown', 'Godown', const ['MC 1']),
                    _buildDropdownField('sf_bookedBy', 'Booked By', const ['CHIRAG']),
                  ],
                ),
                const Divider(),
                // Customer
                TextFormField(
                  controller: _customerNameController,
                  decoration: InputDecoration(
                    labelText: 'Customer Name',
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                       borderRadius: BorderRadius.circular(30),
                       borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                ),
                const SizedBox(height: 8),
                ResponsiveRow(
                  breakpoint: 400,
                  children: [
                    TextFormField(
                      controller: _mobileController,
                      decoration: InputDecoration(
                        labelText: 'Mob. No.',
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                           borderRadius: BorderRadius.circular(30),
                           borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                    ),
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: 'Address',
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                           borderRadius: BorderRadius.circular(30),
                           borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                    ),
                  ],
                ),
                const Divider(),
                // Order Details (Challan/Invoice)
                const Text(
                  'ORDER DETAILS',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Challan'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Invoice'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditablePriceField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
      decoration: InputDecoration(
        labelText: label,
        prefixText: '₹ ',
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      onChanged: (_) {
        setState(() => _calculateTotalPrice());
      },
    );
  }

  Widget _buildPricingAndActions({String buttonLabel = 'Add to Order', VoidCallback? onButtonPressed}) {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            LayoutBuilder(builder: (context, c) {
              bool isNarrow = c.maxWidth < 400;
              return Column(
                children: [
                  // Row 1: R/L Price
                  isNarrow ? Column(
                    children: [
                      _buildEditablePriceField('R Eye Price', _rEyePriceController),
                      const SizedBox(height: 8),
                      _buildEditablePriceField('L Eye Price', _lEyePriceController),
                    ],
                  ) : Row(
                    children: [
                      Expanded(child: _buildEditablePriceField('R Eye Price', _rEyePriceController)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildEditablePriceField('L Eye Price', _lEyePriceController)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Row 2: Delivery Date & Action Button
                  isNarrow ? Column(
                    children: [
                      _buildDeliveryDateField(),
                      const SizedBox(height: 8),
                      _buildActionButton(buttonLabel, onButtonPressed),
                    ],
                  ) : Row(
                    children: [
                      Expanded(flex: 3, child: _buildDeliveryDateField()),
                      const SizedBox(width: 8),
                      Expanded(flex: 4, child: _buildActionButton(buttonLabel, onButtonPressed)),
                    ],
                  ),
                ],
              );
            }),
            const SizedBox(height: 16),
            
             const SizedBox(height: 16),
             
             // Row 3: Total Price & Remarks & Advance
             Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TOTAL PRICE', style: TextStyle(color: Colors.grey[600], fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                        Text(
                          _totalPrice.toStringAsFixed(2), 
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)
                        ),
                        const SizedBox(height: 8),
                        _buildEditablePriceField('ADVANCE PAID', _advancePaidController),
                        const SizedBox(height: 4),
                        Text(
                          'BALANCE: ₹${(_totalPrice - (double.tryParse(_advancePaidController.text) ?? 0.0)).toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red[700]),
                        ),
                      ],
                    )
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _remarksController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'REMARKS',
                        labelStyle: const TextStyle(fontSize: 12, letterSpacing: 1.0),
                        filled: true,
                        fillColor: Colors.white,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
             ),
            const SizedBox(height: 16),

            // Row 4: Place Order & Reset (Robust)
            ResponsiveRow(
              breakpoint: 400,
              children: [
                _buildPlaceAllOrdersButton(),
                _buildResetButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedVendorId,
      decoration: const InputDecoration(
        labelText: 'Vendor',
        isDense: true,
      ),
      items: _vendors.map((vendor) {
        return DropdownMenuItem<String>(
          value: vendor['_id']?.toString() ?? vendor['id']?.toString(),
          child: Text(vendor['name'] ?? 'Unknown Vendor'),
        );
      }).toList(),
      onChanged: (val) {
        setState(() {
          _selectedVendorId = val;
        });
      },
    );
  }

  Widget _buildBillSeriesField() {
    return TextFormField(
      controller: _billSeriesController,
      decoration: InputDecoration(
        labelText: 'Bill Series',
        hintText: 'e.g. ORD_25-26',
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
           borderRadius: BorderRadius.circular(30),
           borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }

  Widget _buildOrderIdField() {
    return TextFormField(
      controller: _orderIdController,
      readOnly: true,
      decoration: InputDecoration(
        labelText: 'Order ID',
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: () => _selectDate(context),
      child: IgnorePointer(
        child: TextFormField(
          controller: _dateController,
          decoration: InputDecoration(
            labelText: 'Date',
            suffixIcon: const Icon(Icons.calendar_today, size: 16),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
               borderRadius: BorderRadius.circular(30),
               borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryDateField() {
    return InkWell(
      onTap: () async {
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now().add(const Duration(days: 7)),
            firstDate: DateTime.now(),
            lastDate: DateTime(2030),
          );
          if (picked != null) {
              final formatted = "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
              setState(() => _deliveryDateController.text = formatted);
          }
      },
      child: IgnorePointer(
          child: TextFormField(
          controller: _deliveryDateController,
          style: const TextStyle(fontSize: 13),
          decoration: const InputDecoration(
              labelText: 'Del. Date',
              suffixIcon: Icon(Icons.calendar_today, size: 14),
              border: OutlineInputBorder(),
              isDense: true,
          ),
          readOnly: true,
          ),
      ),
    );
  }

  Widget _buildActionButton(String label, VoidCallback? onPressed) {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : (onPressed ?? () => _saveOrder()),
        icon: Icon(label.contains('Save') ? Icons.save : Icons.add_shopping_cart, size: 16),
        label: Text(
          _isSaving ? '...' : label, 
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          overflow: TextOverflow.ellipsis,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A237E),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
    );
  }

  Widget _buildPlaceAllOrdersButton() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(30),
      ),
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.send, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                const Text('Place All Orders (0)', style: TextStyle(color: Color(0xFF757575), fontWeight: FontWeight.bold, fontSize: 11)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResetButton() {
    return SizedBox(
        height: 48,
        child: OutlinedButton(
        onPressed: _resetForm,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF1A237E),
          side: const BorderSide(color: Color(0xFF1A237E), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          padding: EdgeInsets.zero,
        ),
        child: const Text('Reset', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
      ),
    );
  }

  Future<void> _searchAndSelectCustomer() async {
    final String query = _customerNameController.text;
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Type a name to search')));
      return;
    }

    final results = await _customerService.searchCustomers(query);
    if (results.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No matching customer found. Filling as new.')));
      return;
    }

    // Show selection dialog
    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Select Customer'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: results.length,
              itemBuilder: (context, index) {
                final c = results[index];
                return ListTile(
                  title: Text(c['name'] ?? ''),
                  subtitle: Text(c['mobile'] ?? ''),
                  onTap: () {
                    setState(() {
                      _customerNameController.text = c['name'] ?? '';
                      _mobileController.text = c['mobile'] ?? '';
                      _addressController.text = c['address'] ?? '';
                      _dobController.text = c['dob'] ?? '';
                      _shouldSaveCustomer = false;
                    });
                    Navigator.pop(ctx);
                  },
                );
              },
            ),
          ),
        ),
      );
    }
  }

  Widget _buildCustomerInfoSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.amber.shade200),
        borderRadius: BorderRadius.circular(20),
      ),
      color: Colors.amber.shade50.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person_pin_outlined, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Text('CUSTOMER INFORMATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber[800], letterSpacing: 1)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.history, size: 20, color: Colors.blue),
                  onPressed: () => _fetchCustomerHistory(_mobileController.text),
                  tooltip: 'Refresh Purchase History',
                ),
                IconButton(
                  icon: const Icon(Icons.search, size: 20, color: Colors.blue),
                  onPressed: _searchAndSelectCustomer,
                  tooltip: 'Search existing customer',
                ),
                TextButton(
                  onPressed: _resetForm,
                  child: const Text('Clear', style: TextStyle(fontSize: 11, color: Colors.red)),
                )
              ],
            ),
            const SizedBox(height: 12),
            Autocomplete<Map<String, dynamic>>(
              initialValue: TextEditingValue(text: _customerNameController.text),
              optionsBuilder: (TextEditingValue textEditingValue) async {
                if (textEditingValue.text.isEmpty) {
                  return await _customerService.getRecentCustomers();
                }
                return await _customerService.searchCustomers(textEditingValue.text);
              },
              displayStringForOption: (option) => option['name'] ?? '',
              onSelected: (Map<String, dynamic> selection) {
                setState(() {
                  // Prioritize the Mongo _id for accounting/ledger linking
                  _selectedCustomerId = selection['_id']?.toString() ?? selection['id']?.toString();
                  _customerNameController.text = selection['name'] ?? '';
                  _mobileController.text = selection['mobile'] ?? '';
                  _addressController.text = selection['address'] ?? '';
                  _dobController.text = selection['dob'] ?? '';
                  _shouldSaveCustomer = false; // Existing customer
                });
                _fetchCustomerHistory(selection['mobile'], name: selection['name']);
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                // Keep the internal controller in sync with our main controller
                if (controller.text != _customerNameController.text) {
                  controller.text = _customerNameController.text;
                }
                controller.addListener(() {
                  if (_customerNameController.text != controller.text) {
                    _customerNameController.text = controller.text;
                  }
                });

                return GestureDetector(
                  onDoubleTap: () {
                    focusNode.unfocus();
                  },
                  child: TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      labelText: 'Customer Name *',
                      prefixIcon: const Icon(Icons.person_outline, size: 20),
                      suffixIcon: Icon(Icons.arrow_drop_down_rounded, color: Colors.blue.withValues(alpha: 0.5)),
                      border: const OutlineInputBorder(),
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (v) => v!.isEmpty ? 'Enter name' : null,
                  ),
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: MediaQuery.of(context).size.width - 64, // Responsive width
                      constraints: const BoxConstraints(maxHeight: 300),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blue.shade50),
                      ),
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (BuildContext context, int index) {
                          final option = options.elementAt(index);
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade50,
                              child: const Icon(Icons.person, color: Colors.blue, size: 20),
                            ),
                            title: Text(option['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(option['mobile'] ?? 'No Mobile'),
                            onTap: () => onSelected(option),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
            
            if (_customerHistory.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.history, size: 14, color: Colors.blue),
                  const SizedBox(width: 6),
                  Text(
                    'PREVIOUS PURCHASES (${_customerHistory.length})',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue, letterSpacing: 1),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _customerHistory.length,
                  itemBuilder: (context, index) {
                    final order = _customerHistory[index];
                    return GestureDetector(
                      onTap: () => _showInvoiceDetailsModal(order),
                      child: Container(
                        width: 150,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.blue.shade100),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              order['date'] ?? '',
                              style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹${order['amount']}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              order['sn'] ?? 'JC-XXX',
                              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                const Icon(Icons.receipt_long_outlined, size: 12, color: Colors.blue),
                                const SizedBox(width: 4),
                                Text('View Details', style: TextStyle(fontSize: 9, color: Colors.blue[700], fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _mobileController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Mobile Number *',
                prefixIcon: Icon(Icons.phone_android_outlined, size: 20),
                border: OutlineInputBorder(),
                isDense: true,
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (v) => v!.length < 10 ? 'Enter valid mobile' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _dobController,
                    decoration: const InputDecoration(
                      labelText: 'DOB',
                      prefixIcon: Icon(Icons.cake_outlined, size: 20),
                      border: OutlineInputBorder(),
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    readOnly: true,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
                        firstDate: DateTime(1920),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        _dobController.text = "${date.day}-${date.month}-${date.year}";
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                      border: OutlineInputBorder(),
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Save this customer to database?', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                const Spacer(),
                Switch(
                  value: _shouldSaveCustomer,
                  onChanged: (v) => setState(() => _shouldSaveCustomer = v),
                  activeColor: Colors.amber,
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            Text('Booking for account: $_currentUserDetailsText', style: const TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }

  void _showAddVendorDialog() {
    final nameCtrl = TextEditingController();
    final printNameCtrl = TextEditingController();
    final aliasCtrl = TextEditingController();
    final accountIdCtrl = TextEditingController(text: 'ACC-${1000 + _vendors.length}');
    final groupCtrl = TextEditingController(text: 'Purchase Account');
    final stationCtrl = TextEditingController(text: 'Local');
    final contactPersonCtrl = TextEditingController(text: 'Admin Manager');
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    String accountType = 'Purchase';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            // Premium Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF1A237E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            
            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('BASIC INFORMATION'),
                    _buildUnifiedField(nameCtrl, 'Name *', Icons.storefront),
                    const SizedBox(height: 16),
                    _buildUnifiedField(printNameCtrl, 'Print Name *', Icons.print_outlined),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildUnifiedField(accountIdCtrl, 'Account Id *', Icons.fingerprint, enabled: false)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildUnifiedField(aliasCtrl, 'Alias', Icons.label_outline)),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    _sectionLabel('GROUPS & STATIONS'),
                    Row(
                      children: [
                        Expanded(child: _buildUnifiedField(groupCtrl, 'Groups *', Icons.group_work_outlined)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildUnifiedField(stationCtrl, 'Stations *', Icons.location_on_outlined)),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    _sectionLabel('CONTACT & IDs'),
                    _buildUnifiedField(contactPersonCtrl, 'Contact Person', Icons.person_outline),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildUnifiedField(phoneCtrl, 'Mobile Number', Icons.phone_android_outlined, isPhone: true)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildUnifiedField(emailCtrl, 'Email', Icons.alternate_email)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: accountType,
                      items: ['Purchase', 'Sales', 'Service'].map((i) => DropdownMenuItem(value: i, child: Text(i, style: const TextStyle(fontSize: 14)))).toList(),
                      onChanged: (val) => accountType = val!,
                      decoration: InputDecoration(
                        labelText: 'Account Type',
                        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
                        prefixIcon: const Icon(Icons.category_outlined, size: 20, color: Color(0xFF1A237E)),
                        border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey[300]!)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            
            // Action Buttons
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
                            _loadMasterData(); // Refresh list in AddOrderScreen
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account added successfully'), backgroundColor: Colors.green));
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

  Widget _buildUnifiedField(TextEditingController ctrl, String label, IconData icon, {bool isPhone = false, bool enabled = true}) {
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

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.blue[900],
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(child: Divider(thickness: 1, color: Color(0xFFE3F2FD))),
      ],
    );
  }


  void _confirmDeleteVendor() {
    if (_selectedVendorId == null) return;
    
    final vendor = _vendors.firstWhere((v) => (v['id']?.toString() ?? v['_id']?.toString()) == _selectedVendorId);
    final name = vendor['name'] ?? vendor['vendorName'] ?? 'this vendor';
    final isAccount = vendor['isAccount'] == true;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vendor?'),
        content: Text('Are you sure you want to delete "$name"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _masterDataService.deleteVendor(_selectedVendorId!, isAccount: isAccount);
              if (success) {
                setState(() => _selectedVendorId = null);
                _loadMasterData();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vendor deleted')));
              } else {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete vendor'), backgroundColor: Colors.red));
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryButton(String category, String label) {
    bool isSelected = _selectedCategory == category;
    return InkWell(
      onTap: () => setState(() {
        _selectedCategory = category;
        _selectedItemId = null;
        _selectedFrameId = null;
        _selectedItem = null;
        _framePrice = 0.0;
        _calculateTotalPrice();
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue),
          boxShadow: isSelected ? [BoxShadow(color: Colors.blue.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))] : null,
        ),
        child: Text(
          label, 
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.blue, 
            fontWeight: FontWeight.bold, 
            fontSize: 11
          )
        ),
      ),
    );
  }

  Widget _buildVendorAndCategorySection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.blue.shade100),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SUPPLY & CATEGORY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue[800], letterSpacing: 1)),
            const SizedBox(height: 16),
            
            // Vendor Selection
            Row(
              children: [
                Expanded(
                  child: Autocomplete<Map<String, dynamic>>(
                    initialValue: TextEditingValue(
                      text: _vendors.firstWhere(
                        (v) => (v['id']?.toString() ?? v['_id']?.toString()) == _selectedVendorId,
                        orElse: () => {},
                      )['name'] ?? '',
                    ),
                    displayStringForOption: (option) => option['name'] ?? '',
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) return _vendors;
                      return _vendors.where((v) => (v['name'] ?? '').toString().toLowerCase().contains(textEditingValue.text.toLowerCase()));
                    },
                    onSelected: (Map<String, dynamic> v) {
                      setState(() {
                        _selectedVendorId = v['id']?.toString() ?? v['_id']?.toString();
                        _selectedItemId = null; // Reset item when vendor changes
                      });
                    },
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                      return TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          labelText: 'Select Vendor (Lab) *',
                          prefixIcon: Icon(Icons.storefront_outlined),
                          border: OutlineInputBorder(),
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (v) => _selectedVendorId == null ? 'Required' : null,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _showAddVendorDialog,
                  icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                  tooltip: 'Add New Vendor',
                ),
                if (_selectedVendorId != null)
                  IconButton(
                    onPressed: _confirmDeleteVendor,
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: 'Delete Selected Vendor',
                  ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Category Toggle
            const Text('What are you purchasing?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildCategoryButton('Lens', 'LENS'),
                _buildCategoryButton('Frame', 'FRAME'),
                _buildCategoryButton('Both', 'BOTH'),
                _buildCategoryButton('Contact Lens', 'CONTACT LENS'),
                _buildCategoryButton('Solutions', 'SOLUTIONS'),
              ],
            ),
            
            if (_selectedCategory == 'Both') ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              const Text('LENS SELECTION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Select Lens *', border: OutlineInputBorder(), isDense: true),
                value: _selectedItemId,
                items: _items.where((i) => i['isFrame'] != true).map((i) => DropdownMenuItem(
                  value: i['id']?.toString(),
                  child: Text(i['itemName'] ?? '', style: const TextStyle(fontSize: 13)),
                )).toList(),
                onChanged: (v) {
                  setState(() => _selectedItemId = v);
                  final item = _items.firstWhere((i) => i['id'] == v, orElse: () => {});
                  if (item.isNotEmpty) _updatePricesFromItem(item);
                },
              ),
              if (_selectedItem != null && _selectedItemId != null) ...[
                const SizedBox(height: 8),
                Builder(
                  builder: (context) {
                    final unitPrice = double.tryParse(_selectedItem!['salePrice']?.toString() ?? '0') ?? 0.0;
                    final qty = (_isRightSelected ? (int.tryParse(_rQtyController.text) ?? 1) : 0) + 
                                (_isLeftSelected ? (int.tryParse(_lQtyController.text) ?? 1) : 0);
                    return Text(
                      '   Lens Price: ₹${(unitPrice * qty).toStringAsFixed(0)}${qty > 1 ? ' (₹${unitPrice.toStringAsFixed(0)} x $qty)' : ''}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 12),
                    );
                  }
                ),
              ],
              const SizedBox(height: 16),
              const Text('FRAME SELECTION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Select Frame *', border: OutlineInputBorder(), isDense: true),
                value: _selectedFrameId,
                items: _items.where((i) => i['isFrame'] == true).map((i) => DropdownMenuItem(
                  value: i['id']?.toString(),
                  child: Text(i['itemName'] ?? '', style: const TextStyle(fontSize: 13)),
                )).toList(),
                onChanged: (v) {
                  setState(() {
                    _selectedFrameId = v;
                    final frame = _items.firstWhere((i) => i['id'] == v, orElse: () => {});
                    if (frame.isNotEmpty) {
                      _framePrice = double.tryParse(frame['salePrice']?.toString() ?? '0') ?? 0.0;
                    }
                    _calculateTotalPrice();
                  });
                },
              ),
              if (_selectedFrameId != null) ...[
                const SizedBox(height: 8),
                Builder(
                  builder: (context) {
                    final qty = (_isRightFrameSelected ? (int.tryParse(_rFrameQtyController.text) ?? 1) : 0) + 
                                (_isLeftFrameSelected ? (int.tryParse(_lFrameQtyController.text) ?? 1) : 0);
                    return Text(
                      '   Frame Price: ₹${(_framePrice * qty).toStringAsFixed(0)}${qty > 1 ? ' (₹${_framePrice.toStringAsFixed(0)} x $qty)' : ''}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 12),
                    );
                  }
                ),
              ],
              if (_selectedFrameId != null) ...[
                const SizedBox(height: 16),
                const Text('FRAME SELECTION DETAILS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                _buildEyeGrid(isFrameOnly: true),
              ],
            ],
          ],
        ),
      ),
    );
  }

  void _showInvoiceDetailsModal(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Invoice Details', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
                    Text(order['sn'] ?? 'JC-XXXX', style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(20)),
                  child: const Text('DELIVERED', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const Divider(height: 32),
            
            // Order Date & Amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoCol('Date', order['date'] ?? ''),
                _buildInfoCol('Total Amount', '₹${order['amount']}', isBold: true),
                _buildInfoCol('Order Type', order['type'] ?? 'RX'),
              ],
            ),
            const SizedBox(height: 24),
            
            const Text('ITEMS & SPECIFICATIONS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey, letterSpacing: 1)),
            const SizedBox(height: 12),
            
            Expanded(
              child: ListView.builder(
                itemCount: (order['items'] as List?)?.length ?? 0,
                itemBuilder: (context, i) {
                  final item = (order['items'] as List)[i];
                  final isRx = order['type'] == 'RX';
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(item['itemName'] ?? 'Product', style: const TextStyle(fontWeight: FontWeight.bold)),
                            if (item['eye'] != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: Colors.blue[100], borderRadius: BorderRadius.circular(8)),
                                child: Text(item['eye'], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                        if (isRx) ...[
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildPowerChip('SPH', item['sph']?.toString() ?? '0.00'),
                              _buildPowerChip('CYL', item['cyl']?.toString() ?? '0.00'),
                              _buildPowerChip('AXIS', item['axis']?.toString() ?? '0'),
                              _buildPowerChip('ADD', item['add']?.toString() ?? '0.00'),
                            ],
                          ),
                        ] else ...[
                          const SizedBox(height: 8),
                          Text('Quantity: ${item['qty'] ?? 1}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('CLOSE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCol(String label, String value, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.w500, fontSize: 14)),
      ],
    );
  }

  Widget _buildPowerChip(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[300]!)),
          child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}


