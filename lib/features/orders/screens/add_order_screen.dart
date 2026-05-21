import 'dart:io'; 
import 'dart:async'; // Added for Timer
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
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
import '../../job_cards/screens/job_cards_list_screen.dart';

import '../widgets/lens_power_matrix_dialog.dart';
import '../../../core/widgets/responsive_row.dart';

class AddOrderScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final List<Map<String, dynamic>>? initialProducts;
  const AddOrderScreen({super.key, this.onBack, this.initialProducts});

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
  Map<String, dynamic>? _currentSavedInvoice;

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
  String _selectedPaymentMethod = 'Cash';
  String _fOrderPowerStrategy = 'Any'; // Added power strategy filter

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
  final _rSphFromController = TextEditingController();
  final _rSphToController = TextEditingController();
  final _rCylController = TextEditingController();
  final _rCylFromController = TextEditingController();
  final _rCylToController = TextEditingController();
  final _rAxisController = TextEditingController();
  final _rAddController = TextEditingController();
  final _rAddFromController = TextEditingController();
  final _rAddToController = TextEditingController();
  final _rQtyController = TextEditingController(text: '1');

  // Eye Data Controllers (Left)
  final _lSphController = TextEditingController();
  final _lSphFromController = TextEditingController();
  final _lSphToController = TextEditingController();
  final _lCylController = TextEditingController();
  final _lCylFromController = TextEditingController();
  final _lCylToController = TextEditingController();
  final _lAxisController = TextEditingController();
  final _lAddController = TextEditingController();
  final _lAddFromController = TextEditingController();
  final _lAddToController = TextEditingController();
  final _lQtyController = TextEditingController(text: '1');
  final _vendorRestockQtyController = TextEditingController(text: '10');

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
  double _totalSpent = 0.0;
  double _maxFrameSpent = 0.0;
  double _maxLensSpent = 0.0;
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

  late Razorpay _razorpay;
  String? _razorpayPendingOrderId;
  double _razorpayPendingAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _initRazorpay();
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

    // Pre-load dynamic items from Smart Cart if passed!
    if (widget.initialProducts != null && widget.initialProducts!.isNotEmpty) {
      String formatRange(dynamic from, dynamic to) {
        final f = from?.toString() ?? '';
        final t = to?.toString() ?? '';
        if (f.isEmpty) return t;
        if (t.isEmpty) return f;
        if (f == t) return f;
        return "$f to $t";
      }

      for (var item in widget.initialProducts!) {
        final price = double.tryParse(item['price']?.toString() ?? '0') ?? 0;
        
        // 🌟 Intelligent Dynamic Autofill: Extract full RX properties from powerSpecs!
        String sph = "";
        String cyl = "";
        String axis = "";
        String add = "";
        
        if (item['powerSpecs'] != null) {
          try {
            final Map<String, dynamic> specs = Map<String, dynamic>.from(item['powerSpecs']);
            // Use Right Eye as primary baseline for both eyes in bulk table view
            final Map<String, dynamic>? activeEye = specs['rightEye'] != null 
              ? Map<String, dynamic>.from(specs['rightEye']) 
              : (specs['leftEye'] != null ? Map<String, dynamic>.from(specs['leftEye']) : null);
            
            if (activeEye != null) {
              sph = formatRange(activeEye['sphFrom'], activeEye['sphTo']);
              cyl = formatRange(activeEye['cylFrom'], activeEye['cylTo']);
              axis = activeEye['axis']?.toString() ?? '';
              add = formatRange(activeEye['addFrom'], activeEye['addTo']);
            }
          } catch (err) {
            debugPrint('⚠️ Failed to parse powerspecs for smart cart auto-fill: $err');
          }
        }

        _bulkItems.add({
          "itemName": item['name'] ?? 'Scanned RFID Product',
          "itemId": item['id']?.toString() ?? '',
          "eye": "BOTH",
          "sph": sph,
          "cyl": cyl,
          "axis": axis,
          "add": add,
          "qty": 1.0,
          "salePrice": price,
          "totalAmount": price,
          "key": DateTime.now().millisecondsSinceEpoch.toString() + _bulkItems.length.toString(),
        });
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _tabController.index = 2; // 🎯 Auto-switch to BULK MODE tab
          _calculateTotalPrice();
        });
      });
    }
  }

  bool _isVendorRequired() {
    // 1. Check active single-item selection (applicable for RX or current selection in list views)
    if (_selectedItemId != null) {
      final item = _items.firstWhere(
        (i) => (i['id']?.toString() ?? i['_id']?.toString()) == _selectedItemId,
        orElse: () => {},
      );
      if (item.isNotEmpty) {
        final double stock = double.tryParse(item['stockQty']?.toString() ?? '0') ?? 0.0;
        if (stock <= 0) return true;
      }
    }

    // For 'Both' mode, also check frame stock
    if (_selectedCategory == 'Both' && _selectedFrameId != null) {
      final frame = _items.firstWhere(
        (i) => (i['id']?.toString() ?? i['_id']?.toString()) == _selectedFrameId,
        orElse: () => {},
      );
      if (frame.isNotEmpty) {
        final double stock = double.tryParse(frame['stockQty']?.toString() ?? '0') ?? 0.0;
        if (stock <= 0) return true;
      }
    }
    
    // 2. Check accumulated items in list views (Single Finish / Bulk)
    if (_tabController.index == 1) {
      for (final itm in _singleFinishItems) {
         final itemId = itm['itemId'];
         final original = _items.firstWhere(
           (i) => (i['id']?.toString() ?? i['_id']?.toString()) == itemId,
           orElse: () => {},
         );
         if (original.isNotEmpty) {
            final double stock = double.tryParse(original['stockQty']?.toString() ?? '0') ?? 0.0;
            if (stock <= 0) return true;
         }
      }
    } else if (_tabController.index == 2) {
      for (final itm in _bulkItems) {
         final itemId = itm['itemId'] ?? itm['combinationId'];
         final original = _items.firstWhere(
           (i) => (i['id']?.toString() ?? i['_id']?.toString()) == itemId,
           orElse: () => {},
         );
         if (original.isNotEmpty) {
            final double stock = double.tryParse(original['stockQty']?.toString() ?? '0') ?? 0.0;
            if (stock <= 0) return true;
         }
      }
    }

    return false; // Hide by default or if item is fully stocked
  }


  void _initRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleRazorpaySuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleRazorpayError);
  }

  void _handleRazorpaySuccess(PaymentSuccessResponse response) async {
    try {
      final authService = AuthService();
      await authService.verifyPaymentAndRegister(
        orderId: response.orderId ?? '',
        paymentId: response.paymentId ?? '',
        signature: response.signature ?? '',
        userData: {
          'name': _customerNameController.text.isNotEmpty ? _customerNameController.text : 'Unnamed Customer',
          'email': 'vikas@example.com',
          'password': 'RENEWAL_DUMMY_PASSWORD',
          'phone': _mobileController.text.isNotEmpty ? _mobileController.text : '9876543210',
          'address': _addressController.text.isNotEmpty ? _addressController.text : 'Mumbai, Maharashtra',
          'subscriptionPlan': 'Order Save Payment',
        },
        subscriptionPlan: 'Order Save Payment',
      );
    } catch (e) {
      debugPrint('Backend payment verification failed: $e');
    }

    if (_razorpayPendingOrderId != null && _razorpayPendingAmount > 0) {
      await _collectionService.recordPayment(
        orderId: _razorpayPendingOrderId!,
        customerName: _customerNameController.text,
        accountId: _selectedCustomerId,
        amount: _razorpayPendingAmount,
        date: _dateController.text,
        paymentMode: 'Razorpay',
      );
    }

    if (_currentSavedInvoice != null) {
      final double basePaid = double.tryParse(_currentSavedInvoice!['paidAmount']?.toString() ?? '0.0') ?? 0.0;
      final double newPaid = basePaid + _razorpayPendingAmount;
      _currentSavedInvoice!['paidAmount'] = newPaid;
      _currentSavedInvoice!['dueAmount'] = (_currentSavedInvoice!['totalAmount'] as double) - newPaid;
    }

    if (mounted) {
      try { Navigator.of(context).pop(); } catch (_) {} // Close payment modal if present
      if (_currentSavedInvoice != null) {
        _showNativeInvoiceDialog(_currentSavedInvoice!);
      } else {
        _resetForm();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order Saved & Razorpay Payment Successful!'), backgroundColor: Colors.green),
        );
      }
    }
  }

  void _handleRazorpayError(PaymentFailureResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Razorpay Payment Failed: ${response.message ?? "Cancelled"}'), backgroundColor: Colors.red),
      );
    }
  }

  void _startRazorpayPayment(double amount, String orderId) async {
    _razorpayPendingOrderId = orderId;
    _razorpayPendingAmount = amount;

    final isMobile = !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

    if (!isMobile) {
      // Simulation mode for Desktop & Web (to allow testing and development on Chrome)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Simulating Razorpay checkout on Web/Desktop...'), backgroundColor: Colors.blue),
        );
      }
      await Future.delayed(const Duration(seconds: 2));
      _handleRazorpaySuccess(PaymentSuccessResponse('simulated_pay_id', 'simulated_order_id', 'simulated_signature', null));
      return;
    }

    try {
      final authService = AuthService();
      final orderResult = await authService.createRazorpayOrder(
        amount: amount,
        name: _customerNameController.text.isNotEmpty ? _customerNameController.text : 'Unnamed Customer',
        email: 'vikas@example.com',
        phone: _mobileController.text.isNotEmpty ? _mobileController.text : '9876543210',
        subscriptionPlan: 'Order Save Payment',
      );

      if (orderResult['success'] == true) {
        final rzpOrderId = orderResult['id']?.toString() ?? '';
        final keyId = orderResult['keyId']?.toString() ?? 'rzp_live_SoqYaLiOI6KmXVV';
        final amountInPaise = orderResult['amount'] as int? ?? (amount * 100).toInt();

        var options = {
          'key': keyId,
          'amount': amountInPaise,
          'name': 'Retail Lens',
          'order_id': rzpOrderId,
          'description': 'Order Payment - ID: $orderId',
          'prefill': {
            'contact': _mobileController.text.isNotEmpty ? _mobileController.text : '9876543210',
            'email': 'vikas@example.com',
          }
        };

        _razorpay.open(options);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(orderResult['message'] ?? 'Could not create Razorpay order.'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Razorpay Initialization Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
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
        _currentUserDetailsText = name.isNotEmpty ? name : mobile;
        
        // Keep input fields completely clean and blank for new customer entry
        _customerNameController.text = '';
        _mobileController.text = '';
        _addressController.text = '';
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
        
        // Match completed/active statuses case-insensitively
        final statusStr = o['status']?.toString().toLowerCase() ?? '';
        bool statusMatch = statusStr == 'delivered' || 
                           statusStr == 'ready' || 
                           statusStr == 'in progress' || 
                           statusStr == 'completed';
        
        return (mobileMatch || nameMatch) && (statusMatch || o['status'] == 'Delivered');
      }).toList();

      // Sort by date descending
      history.sort((a, b) {
        final dateA = a['sortDate'] as DateTime? ?? DateTime.tryParse(a['date'] ?? '') ?? DateTime(2000);
        final dateB = b['sortDate'] as DateTime? ?? DateTime.tryParse(b['date'] ?? '') ?? DateTime(2000);
        return dateB.compareTo(dateA);
      });

      // Calculate aggregates
      double total = 0.0;
      double maxFrame = 0.0;
      double maxLens = 0.0;

      for (var order in history) {
        final amt = double.tryParse(order['amount']?.toString() ?? '0') ?? 0.0;
        total += amt;

        final items = order['items'] as List? ?? [];
        for (var item in items) {
          final desc = (item['description'] ?? item['itemName'] ?? '').toString().toLowerCase();
          final itemPrice = double.tryParse(item['unitPrice']?.toString() ?? item['salePrice']?.toString() ?? item['lineTotal']?.toString() ?? '0') ?? 0.0;

          if (desc.contains('frame')) {
            if (itemPrice > maxFrame) maxFrame = itemPrice;
          } else if (desc.contains('lens')) {
            if (itemPrice > maxLens) maxLens = itemPrice;
          } else {
            // Fallback: Check order type
            final oType = order['type']?.toString().toUpperCase() ?? '';
            if (oType == 'FRAME' && itemPrice > maxFrame) {
              maxFrame = itemPrice;
            } else if (oType == 'LENS' && itemPrice > maxLens) {
              maxLens = itemPrice;
            }
          }
        }
      }
      
      setState(() {
        _customerHistory = history;
        _totalSpent = total;
        _maxFrameSpent = maxFrame;
        _maxLensSpent = maxLens;
      });
      debugPrint('📚 [History] Result: ${history.length} records found, spent: $total, maxFrame: $maxFrame, maxLens: $maxLens');
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
        if (args.containsKey('preloadedProduct')) {
          _preloadProductFromScan(args['preloadedProduct']);
        } else {
          _populateForm(args);
        }
      }
      _isDataLoaded = true;
    }
  }

  void _preloadProductFromScan(Map<String, dynamic> product) {
    setState(() {
      final String prodId = product['id']?.toString() ?? product['_id']?.toString() ?? 'SCANNED_${DateTime.now().millisecondsSinceEpoch}';
      final String name = product['itemName'] ?? product['name'] ?? 'Scanned Product';
      final String cat = product['mainCategory'] ?? product['kind'] ?? product['category'] ?? 'Lens';
      final bool isFr = product['isFrame'] == true || cat.toLowerCase().contains('frame') || name.toLowerCase().contains('frame');
      
      final Map<String, dynamic> fullProduct = {
        ...product,
        'id': prodId,
        '_id': prodId,
        'itemName': name,
        'name': name,
        'salePrice': double.tryParse(product['salePrice']?.toString() ?? '0') ?? 0.0,
        'stockQty': double.tryParse((product['stockQty'] ?? product['stockQuantity'])?.toString() ?? '0') ?? 0.0,
        'mainCategory': cat,
        'isFrame': isFr,
      };

      // Safe Injection: If scanned product is not yet in loaded items list, inject it
      final bool alreadyExists = _items.any((i) => (i['id']?.toString() ?? i['_id']?.toString()) == prodId);
      if (!alreadyExists) {
        _items.add(fullProduct);
      }

      _selectedItemId = prodId;
      _selectedItem = fullProduct;
      _itemNameController.text = name;
      
      // Intelligently map category
      if (isFr) {
        _selectedCategory = 'Frame';
      } else if (name.toLowerCase().contains('contact') || cat.toLowerCase().contains('contact')) {
        _selectedCategory = 'Contact Lens';
      } else if (name.toLowerCase().contains('solution') || cat.toLowerCase().contains('solution')) {
        _selectedCategory = 'Solutions';
      } else {
        _selectedCategory = 'Lens';
      }

      _fOrderPowerStrategy = 'Any'; // 💡 CRITICAL FIX: Clear strategy filters so QR loaded items are NEVER hidden!

      // Trigger standard Pricing engine
      _updatePricesFromItem(fullProduct);

      // 🌟 Advanced Feature: Auto-populate RX Power Specifications directly from Product Data!
      if (product['powerSpecs'] != null) {
        try {
          final Map<String, dynamic> specs = Map<String, dynamic>.from(product['powerSpecs']);
          
          String formatRange(dynamic from, dynamic to) {
            final f = from?.toString() ?? '';
            final t = to?.toString() ?? '';
            if (f.isEmpty) return t;
            if (t.isEmpty) return f;
            if (f == t) return f;
            return "$f to $t";
          }

          // Populate Right Eye Baseline Values
          if (specs['rightEye'] != null) {
            final Map<String, dynamic> r = Map<String, dynamic>.from(specs['rightEye']);
            _rSphController.text = formatRange(r['sphFrom'], r['sphTo']);
            _rSphFromController.text = r['sphFrom']?.toString() ?? '';
            _rSphToController.text = r['sphTo']?.toString() ?? '';
            _rCylController.text = formatRange(r['cylFrom'], r['cylTo']);
            _rCylFromController.text = r['cylFrom']?.toString() ?? '';
            _rCylToController.text = r['cylTo']?.toString() ?? '';
            _rAxisController.text = r['axis']?.toString() ?? '';
            _rAddController.text = formatRange(r['addFrom'], r['addTo']);
            _rAddFromController.text = r['addFrom']?.toString() ?? '';
            _rAddToController.text = r['addTo']?.toString() ?? '';
            _rQtyController.text = r['qty']?.toString() ?? '1';
            _isRightSelected = true;
          }
          
          // Populate Left Eye Baseline Values
          if (specs['leftEye'] != null) {
            final Map<String, dynamic> l = Map<String, dynamic>.from(specs['leftEye']);
            _lSphController.text = formatRange(l['sphFrom'], l['sphTo']);
            _lSphFromController.text = l['sphFrom']?.toString() ?? '';
            _lSphToController.text = l['sphTo']?.toString() ?? '';
            _lCylController.text = formatRange(l['cylFrom'], l['cylTo']);
            _lCylFromController.text = l['cylFrom']?.toString() ?? '';
            _lCylToController.text = l['cylTo']?.toString() ?? '';
            _lAxisController.text = l['axis']?.toString() ?? '';
            _lAddController.text = formatRange(l['addFrom'], l['addTo']);
            _lAddFromController.text = l['addFrom']?.toString() ?? '';
            _lAddToController.text = l['addTo']?.toString() ?? '';
            _lQtyController.text = l['qty']?.toString() ?? '1';
            _isLeftSelected = true;
          }
          
          // 🌟 Auto-select matching Power Layout Strategy based on parsed specs!
          if (_isRightSelected && _isLeftSelected) {
            final bool sameSph = _rSphController.text == _lSphController.text;
            final bool sameCyl = _rCylController.text == _lCylController.text;
            final bool sameAxis = _rAxisController.text == _lAxisController.text;
            
            if (sameSph && sameCyl && sameAxis) {
              _fOrderPowerStrategy = 'Both (Same)';
            } else {
              _fOrderPowerStrategy = 'Both (Diff)';
            }
          } else if (_isRightSelected) {
            _fOrderPowerStrategy = 'Single R';
          } else if (_isLeftSelected) {
            _fOrderPowerStrategy = 'Single L';
          }

          debugPrint('✨ Dynamically populated RX Power Specifications & set strategy to $_fOrderPowerStrategy!');
        } catch (e) {
          debugPrint('⚠️ Failed to auto-parse power specs: $e');
        }
      }
    });
    
    debugPrint('🚀 Successfully Preloaded Product: ${product['name']} from QR Scan.');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎯 Pre-loaded "${product['name']}" details into bill!'),
          backgroundColor: Colors.indigo[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
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
        
        // 🛡️ CRITICAL FIX: Preserve scanned preloaded item inside list if overwrite occurs
        if (_selectedItemId != null && _selectedItem != null) {
           final bool exists = items.any((i) => (i['id']?.toString() ?? i['_id']?.toString()) == _selectedItemId);
           if (!exists) {
             items.add(_selectedItem!);
           }
        }
        
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
        
        saleItems.add({
          "barcode": "",
          "itemName": _itemNameController.text,
          "unit": "",
          "dia": "",
          "eye": eye,
          "sph": sph,
          "cyl": cyl,
          "axis": axis,
          "add": add,
          "qty": qty,
          "purchasePrice": 0,
          "salePrice": price,
          "discount": 0,
          "totalAmount": total,
          "sellPrice": 0,
          "combinationId": _selectedItemId ?? "6970852e152a18a6ad847335",
        });
      }
      
      String compileRange(String from, String to) {
        final f = from.trim();
        final t = to.trim();
        if (f.isEmpty) return t;
        if (t.isEmpty) return f;
        if (f == t) return f;
        return "$f to $t";
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
            "sph": item['sph']?.toString() ?? '',
            "cyl": item['cyl']?.toString() ?? '',
            "axis": item['axis']?.toString() ?? '',
            "add": item['add']?.toString() ?? '',
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
             addSaleItem('R', compileRange(_rSphFromController.text, _rSphToController.text), compileRange(_rCylFromController.text, _rCylToController.text), _rAxisController.text, compileRange(_rAddFromController.text, _rAddToController.text), _rQtyController.text, _rEyePrice);
           }
           if (_isLeftSelected) {
              if (_fOrderPowerStrategy == 'Both (Same)') {
                addSaleItem('L', compileRange(_rSphFromController.text, _rSphToController.text), compileRange(_rCylFromController.text, _rCylToController.text), _rAxisController.text, compileRange(_rAddFromController.text, _rAddToController.text), _rQtyController.text, _lEyePrice);
              } else {
                addSaleItem('L', compileRange(_lSphFromController.text, _lSphToController.text), compileRange(_lCylFromController.text, _lCylToController.text), _lAxisController.text, compileRange(_lAddFromController.text, _lAddToController.text), _lQtyController.text, _lEyePrice);
              }
           }
        }
      } else {
        // RX Mode
        if (_isRightSelected) {
          addSaleItem('R', compileRange(_rSphFromController.text, _rSphToController.text), compileRange(_rCylFromController.text, _rCylToController.text), _rAxisController.text, compileRange(_rAddFromController.text, _rAddToController.text), _rQtyController.text, _rEyePrice);
        }
        if (_isLeftSelected) {
           if (_fOrderPowerStrategy == 'Both (Same)') {
             addSaleItem('L', compileRange(_rSphFromController.text, _rSphToController.text), compileRange(_rCylFromController.text, _rCylToController.text), _rAxisController.text, compileRange(_rAddFromController.text, _rAddToController.text), _rQtyController.text, _lEyePrice);
           } else {
             addSaleItem('L', compileRange(_lSphFromController.text, _lSphToController.text), compileRange(_lCylFromController.text, _lCylToController.text), _lAxisController.text, compileRange(_lAddFromController.text, _lAddToController.text), _lQtyController.text, _lEyePrice);
           }
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
          'paymentMode': _selectedPaymentMethod,
          'vendorProcurement': _selectedVendorId != null && double.tryParse(_selectedItem?['stockQty']?.toString() ?? '0') == 0.0 ? {
              'vendorId': _selectedVendorId,
              'restockQty': int.tryParse(_vendorRestockQtyController.text) ?? 10,
              'isOutOfStockBackorder': true,
          } : null,
      };
      
      // Save OR UPDATE Customer if enabled
      if (_shouldSaveCustomer) {
        final customerPayload = {
          'name': _customerNameController.text,
          'mobile': _mobileController.text,
          'address': _addressController.text,
          'dob': _dobController.text,
        };

        String? targetId = _selectedCustomerId;
        
        // If not already selected, verify if customer exists by phone
        if (targetId == null) {
          final cleanedTarget = _mobileController.text.replaceAll(' ', '').replaceAll('+91', '');
          final existingList = await _customerService.searchCustomers(_mobileController.text);
          final match = existingList.firstWhere(
            (c) => c['mobile'].toString().replaceAll(' ', '').replaceAll('+91', '') == cleanedTarget,
            orElse: () => {},
          );
          if (match.isNotEmpty) {
            targetId = match['_id']?.toString() ?? match['id']?.toString();
          }
        }

        if (targetId != null) {
          // UPDATE EXISTING
          final updated = await _customerService.updateCustomer(targetId, customerPayload);
          if (updated != null) {
             _selectedCustomerId = targetId;
             debugPrint('✅ Updated existing customer profile!');
          }
        } else {
          // CREATE NEW
          final newCustomer = await _customerService.saveCustomer(customerPayload);
          if (newCustomer != null && (newCustomer['_id'] != null || newCustomer['id'] != null)) {
            _selectedCustomerId = (newCustomer['_id'] ?? newCustomer['id']).toString();
          }
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
        
        final advancePaid = double.tryParse(_advancePaidController.text) ?? 0.0;
        final savedOrderId = result?['data']?['_id'] ?? result?['data']?['id'] ?? uniqueBillNo;
        
        _currentSavedInvoice = {
          'billNo': savedOrderId,
          'customerId': _customerNameController.text.isNotEmpty ? _customerNameController.text : 'Unnamed Customer',
          'status': 'SAVED',
          'totalAmount': netAmt,
          'paidAmount': advancePaid,
          'dueAmount': netAmt - advancePaid,
          'createdAt': DateTime.now().toIso8601String(),
          'customer': {
            'fullName': _customerNameController.text.isNotEmpty ? _customerNameController.text : 'Customer',
            'phone': _mobileController.text,
          },
          'items': saleItems.map((e) => {
            'description': e['itemName'] ?? 'Product',
            'quantity': double.tryParse(e['qty']?.toString() ?? '1')?.toInt() ?? 1,
            'lineTotal': double.tryParse(e['totalAmount']?.toString() ?? '0') ?? 0.0,
            'sph': e['sph'] ?? '',
            'cyl': e['cyl'] ?? '',
            'eye': e['eye'] ?? '',
          }).toList(),
        };

        if (advancePaid < netAmt) {
          // Show Payment Modal for final confirmation
          _showPaymentModal(netAmt, savedOrderId, uniqueBillNo, saleItems, netAmt, advancePaid);
        } else {
          if (_selectedPaymentMethod == 'Razorpay') {
            _startRazorpayPayment(advancePaid, savedOrderId);
          } else {
            // Fully paid upfront, trigger the Invoice and share workflow immediately!
            _triggerInvoiceWorkflow(savedOrderId, netAmt, advancePaid, saleItems);
          }
        }
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

  void _showPaymentModal(double totalAmount, String orderId, String displayOrderId, List<dynamic> saleItems, double fullTotal, [double initialAdvance = 0.0]) {
    double paidAmount = initialAdvance;
    bool sendWhatsAppReminder = false;
    String selectedPaymentMethod = _selectedPaymentMethod;
    final TextEditingController amountController = TextEditingController(text: initialAdvance > 0 ? initialAdvance.toStringAsFixed(0) : '');
    
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
              Text('Order ID: $displayOrderId', style: const TextStyle(color: Colors.grey, fontSize: 13)),
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
                controller: amountController,
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

               const Text('Payment Mode:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildPaymentMethodChip('Cash', Icons.payments_outlined, selectedPaymentMethod, (val) {
                    setModalState(() => selectedPaymentMethod = val);
                  }),
                  _buildPaymentMethodChip('Card', Icons.credit_card_outlined, selectedPaymentMethod, (val) {
                    setModalState(() => selectedPaymentMethod = val);
                  }),
                  _buildPaymentMethodChip('UPI', Icons.qr_code_scanner_outlined, selectedPaymentMethod, (val) {
                    setModalState(() => selectedPaymentMethod = val);
                  }),
                  _buildPaymentMethodChip('Razorpay', Icons.payment_rounded, selectedPaymentMethod, (val) {
                    setModalState(() => selectedPaymentMethod = val);
                  }),
                ],
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
                    final double extraPayment = paidAmount - initialAdvance;
                    if (extraPayment > 0) {
                      if (selectedPaymentMethod == 'Razorpay') {
                        _startRazorpayPayment(extraPayment, orderId);
                        return; // Razorpay handler will take over from here on success!
                      }
                      
                      // 1. Record the Receipt Voucher (for Accounting/Reports) only for the extra amount
                      final success = await _collectionService.recordPayment(
                        orderId: orderId,
                        customerName: _customerNameController.text,
                        accountId: _selectedCustomerId, // Passing the linked ID
                        amount: extraPayment,
                        date: _dateController.text,
                        paymentMode: selectedPaymentMethod,
                      );
                      
                      if (!success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Order saved, but additional Payment Record failed!'), backgroundColor: Colors.orange)
                        );
                      }
                    }
                    final double totalPaidOverall = paidAmount;
                    
                    Navigator.pop(ctx); // Close the payment modal first
                    _triggerInvoiceWorkflow(orderId, fullTotal, totalPaidOverall, saleItems);
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

  Widget _buildPaymentMethodChip(String name, IconData icon, String selected, Function(String) onTap) {
    final isSelected = selected == name;
    return GestureDetector(
      onTap: () => onTap(name),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A237E) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFF1A237E) : Colors.grey[300]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.black87),
            const SizedBox(width: 6),
            Text(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _razorpay.clear();
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
    _rSphFromController.dispose();
    _rSphToController.dispose();
    _rCylController.dispose();
    _rCylFromController.dispose();
    _rCylToController.dispose();
    _rAxisController.dispose();
    _rAddController.dispose();
    _rAddFromController.dispose();
    _rAddToController.dispose();
    _rQtyController.dispose();
    _lSphController.dispose();
    _lSphFromController.dispose();
    _lSphToController.dispose();
    _lCylController.dispose();
    _lCylFromController.dispose();
    _lCylToController.dispose();
    _lAxisController.dispose();
    _lAddController.dispose();
    _lAddFromController.dispose();
    _lAddToController.dispose();
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
    _rSphFromController.clear();
    _rSphToController.clear();
    _rCylController.clear();
    _rCylFromController.clear();
    _rCylToController.clear();
    _rAxisController.clear();
    _rAddController.clear();
    _rAddFromController.clear();
    _rAddToController.clear();
    _rQtyController.text = '1'; // Default Qty
    
    _lSphController.clear();
    _lSphFromController.clear();
    _lSphToController.clear();
    _lCylController.clear();
    _lCylFromController.clear();
    _lCylToController.clear();
    _lAxisController.clear();
    _lAddController.clear();
    _lAddFromController.clear();
    _lAddToController.clear();
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
      _customerHistory.clear();
      _totalSpent = 0.0;
      _maxFrameSpent = 0.0;
      _maxLensSpent = 0.0;
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
      body: Form(
        key: _formKey,
        child: RefreshIndicator(
          onRefresh: _loadMasterData,
          child: _buildRXForm(),
        ),
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
                    _buildPowerStrategySelector(), // Injected Strategy Selector
                    DropdownButtonFormField<String>(
                      isExpanded: true,
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
                        if (_selectedCategory == 'Lens') {
                          return !isFr && cat.contains('lens') && !cat.contains('contact') && _matchesStrategy(i);
                        }
                        if (_selectedCategory == 'Frame') return isFr;
                        if (_selectedCategory == 'Contact Lens') {
                          return cat.contains('contact') && _matchesStrategy(i);
                        }
                        if (_selectedCategory == 'Solutions') return cat.contains('solution');
                        return true;
                      }).map((i) {
                        final double stock = double.tryParse(i['stockQty']?.toString() ?? '0') ?? 0.0;
                        final itemName = i['itemName'] ?? 'Unknown Item';
                        return DropdownMenuItem(
                          value: i['id']?.toString() ?? i['_id']?.toString(),
                          child: Text(
                             "$itemName (Qty: ${stock.toInt()})", 
                             overflow: TextOverflow.ellipsis,
                             maxLines: 1,
                             style: TextStyle(
                               fontSize: 13,
                               color: stock <= 0 ? Colors.red[700] : Colors.black87,
                               fontWeight: stock <= 0 ? FontWeight.bold : FontWeight.normal
                             )
                          ),
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

                    // 🏪 SMART PROCUREMENT: Out of Stock & Vendor Back-Order Injection
                    Builder(
                      builder: (context) {
                        if (_selectedItem == null || _selectedItemId == null) return const SizedBox();
                        final double stock = double.tryParse(_selectedItem!['stockQty']?.toString() ?? '0') ?? 0.0;
                        if (stock > 0) return const SizedBox();
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.red[200]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 24),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('⚠️ OUT OF STOCK!', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.red[900], fontSize: 13)),
                                        const SizedBox(height: 2),
                                        Text('This item has 0 stock. Please select a Vendor above to place a restock back-order.', style: TextStyle(color: Colors.red[800], fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            // The Elite Vendor Procurement Card
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft, 
                                  end: Alignment.bottomRight, 
                                  colors: [const Color(0xFF0D1B2A), Colors.indigo[900]!]
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.blueAccent.withOpacity(0.5), width: 1.5),
                                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.local_shipping_outlined, color: Colors.amber[400], size: 20),
                                      const SizedBox(width: 8),
                                      const Text('VENDOR RESTOCK PLANNER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.8)),
                                    ],
                                  ),
                                  const Divider(color: Colors.white24, height: 20),
                                  
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.storefront_outlined, color: Colors.amberAccent, size: 18),
                                        const SizedBox(width: 8),
                                        const Text('Assigned Vendor (Lab): ', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                                        Expanded(
                                          child: Builder(
                                            builder: (context) {
                                              final vendor = _vendors.firstWhere(
                                                (v) => (v['id']?.toString() ?? v['_id']?.toString()) == _selectedVendorId,
                                                orElse: () => {},
                                              );
                                              final vName = vendor['name'] ?? '⚠️ NOT SELECTED (Select Above)';
                                              return Text(
                                                vName, 
                                                style: TextStyle(
                                                  color: _selectedVendorId == null ? Colors.amberAccent : Colors.white, 
                                                  fontWeight: FontWeight.w900, 
                                                  fontSize: 12
                                                ),
                                                textAlign: TextAlign.end,
                                                overflow: TextOverflow.ellipsis,
                                              );
                                            }
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Customer Qty', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                            const SizedBox(height: 4),
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              width: double.infinity,
                                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                                              child: Builder(
                                                builder: (context) {
                                                  final cQty = (_isRightSelected ? (int.tryParse(_rQtyController.text) ?? 1) : 0) + 
                                                              (_isLeftSelected ? (int.tryParse(_lQtyController.text) ?? 1) : 0);
                                                  return Text('$cQty Pc${cQty > 1 ? "s" : ""}', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w900));
                                                }
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Restock Qty (Vendor)', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                            const SizedBox(height: 4),
                                            SizedBox(
                                              height: 38,
                                              child: TextFormField(
                                                controller: _vendorRestockQtyController,
                                                keyboardType: TextInputType.number,
                                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                                textAlign: TextAlign.center,
                                                decoration: InputDecoration(
                                                  filled: true,
                                                  fillColor: Colors.white.withOpacity(0.15),
                                                  contentPadding: EdgeInsets.zero,
                                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white38)),
                                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white38)),
                                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.amber, width: 1.5)),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        );
                      }
                    ),

                    
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

  bool _matchesStrategy(dynamic item) {
    if (_fOrderPowerStrategy == 'Any') return true;
    final specs = item['powerSpecs'];
    if (specs == null || specs is! Map || specs.isEmpty) return true; // Allow generic/test lenses
    
    final r = specs['rightEye'];
    final l = specs['leftEye'];
    final bool hasR = r != null && r is Map && ((r['sphFrom']?.toString() ?? '').isNotEmpty || (r['sphTo']?.toString() ?? '').isNotEmpty);
    final bool hasL = l != null && l is Map && ((l['sphFrom']?.toString() ?? '').isNotEmpty || (l['sphTo']?.toString() ?? '').isNotEmpty);
    
    if (_fOrderPowerStrategy == 'Single R') return hasR && !hasL;
    if (_fOrderPowerStrategy == 'Single L') return !hasR && hasL;
    
    if (_fOrderPowerStrategy == 'Both (Same)') {
      if (!hasR || !hasL) return false;
      final rs = '${r['sphFrom']}-${r['sphTo']}-${r['cylFrom']}-${r['cylTo']}-${r['axis']}';
      final ls = '${l['sphFrom']}-${l['sphTo']}-${l['cylFrom']}-${l['cylTo']}-${l['axis']}';
      return rs == ls;
    }
    if (_fOrderPowerStrategy == 'Both (Diff)') {
      if (!hasR || !hasL) return false;
      final rs = '${r['sphFrom']}-${r['sphTo']}-${r['cylFrom']}-${r['cylTo']}-${r['axis']}';
      final ls = '${l['sphFrom']}-${l['sphTo']}-${l['cylFrom']}-${l['cylTo']}-${l['axis']}';
      return rs != ls;
    }
    return true;
  }

  Widget _buildPowerStrategySelector() {
    if (_selectedCategory != 'Lens' && _selectedCategory != 'Contact Lens' && _selectedCategory != 'Both') {
      return const SizedBox.shrink(); 
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('POWER LAYOUT STRATEGY:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
        const SizedBox(height: 4),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['Any', 'Single R', 'Single L', 'Both (Same)', 'Both (Diff)'].map((m) {
              final isSel = _fOrderPowerStrategy == m;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(m, style: TextStyle(fontSize: 11, color: isSel ? Colors.white : Colors.black87)),
                  selected: isSel,
                  selectedColor: const Color(0xFF1A237E),
                  checkmarkColor: Colors.white,
                  onSelected: (v) {
                    setState(() {
                      _fOrderPowerStrategy = m;
                      _selectedItemId = null;
                      
                      // 🔄 Sync visual checkboxes based on the active strategy instantly!
                      if (m == 'Single R') {
                        _isRightSelected = true;
                        _isLeftSelected = false;
                      } else if (m == 'Single L') {
                        _isRightSelected = false;
                        _isLeftSelected = true;
                      } else { // 'Both (Same)', 'Both (Diff)', 'Any'
                        _isRightSelected = true;
                        _isLeftSelected = true;
                      }
                      _calculateTotalPrice();
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
      ],
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
                const Expanded(flex: 3, child: Center(child: Text('SPH RANGE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black87)))),
                const SizedBox(width: 2),
                const Expanded(flex: 3, child: Center(child: Text('CYL RANGE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black87)))),
                const SizedBox(width: 2),
                const Expanded(flex: 3, child: Center(child: Text('AXIS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black87)))),
                const SizedBox(width: 2),
                if (showAdd) ...[
                  const Expanded(flex: 3, child: Center(child: Text('ADD RANGE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black87)))),
                  const SizedBox(width: 2),
                ],
              ],
              const Expanded(flex: 2, child: Text('QTY', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black87))),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (_fOrderPowerStrategy != 'Single L') ...[
          _buildEyeRow(
            eye: _fOrderPowerStrategy == 'Both (Same)' ? 'BOTH' : 'R', 
            isSelected: isFrameOnly ? _isRightFrameSelected : _isRightSelected, 
            onChanged: (val) => setState(() {
              if (isFrameOnly) _isRightFrameSelected = val!; else _isRightSelected = val!;
              _calculateTotalPrice();
            }),
            sphFrom: (isFrameOnly || _selectedCategory == 'Solutions' || _selectedCategory == 'Frame') ? null : _rSphFromController,
            sphTo: (isFrameOnly || _selectedCategory == 'Solutions' || _selectedCategory == 'Frame') ? null : _rSphToController,
            cylFrom: (isFrameOnly || _selectedCategory == 'Solutions' || _selectedCategory == 'Frame') ? null : _rCylFromController,
            cylTo: (isFrameOnly || _selectedCategory == 'Solutions' || _selectedCategory == 'Frame') ? null : _rCylToController,
            axis: (isFrameOnly || _selectedCategory == 'Solutions' || _selectedCategory == 'Frame') ? null : _rAxisController,
            addFrom: (isFrameOnly || _selectedCategory == 'Solutions' || _selectedCategory == 'Frame' || !showAdd) ? null : _rAddFromController,
            addTo: (isFrameOnly || _selectedCategory == 'Solutions' || _selectedCategory == 'Frame' || !showAdd) ? null : _rAddToController,
            qty: isFrameOnly ? _rFrameQtyController : _rQtyController,
          ),
          const SizedBox(height: 8),
        ],
        if (_fOrderPowerStrategy != 'Single R' && _fOrderPowerStrategy != 'Both (Same)') ...[
          _buildEyeRow(
            eye: 'L', 
            isSelected: isFrameOnly ? _isLeftFrameSelected : _isLeftSelected, 
            onChanged: (val) => setState(() {
              if (isFrameOnly) _isLeftFrameSelected = val!; else _isLeftSelected = val!;
              _calculateTotalPrice();
            }),
            sphFrom: (isFrameOnly || _selectedCategory == 'Solutions' || _selectedCategory == 'Frame') ? null : _lSphFromController,
            sphTo: (isFrameOnly || _selectedCategory == 'Solutions' || _selectedCategory == 'Frame') ? null : _lSphToController,
            cylFrom: (isFrameOnly || _selectedCategory == 'Solutions' || _selectedCategory == 'Frame') ? null : _lCylFromController,
            cylTo: (isFrameOnly || _selectedCategory == 'Solutions' || _selectedCategory == 'Frame') ? null : _lCylToController,
            axis: (isFrameOnly || _selectedCategory == 'Solutions' || _selectedCategory == 'Frame') ? null : _lAxisController,
            addFrom: (isFrameOnly || _selectedCategory == 'Solutions' || _selectedCategory == 'Frame' || !showAdd) ? null : _lAddFromController,
            addTo: (isFrameOnly || _selectedCategory == 'Solutions' || _selectedCategory == 'Frame' || !showAdd) ? null : _lAddToController,
            qty: isFrameOnly ? _lFrameQtyController : _lQtyController,
          ),
        ],
      ],
    );
  }

  Widget _buildEyeRow({
    required String eye,
    required bool isSelected,
    required ValueChanged<bool?> onChanged,
    TextEditingController? sphFrom,
    TextEditingController? sphTo,
    TextEditingController? cylFrom,
    TextEditingController? cylTo,
    TextEditingController? axis,
    TextEditingController? addFrom,
    TextEditingController? addTo,
    required TextEditingController qty,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue[50]!.withValues(alpha: 0.5) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: FittedBox(
              fit: BoxFit.scaleDown,
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
          ),
          const SizedBox(width: 2),
          if (sphFrom != null) ...[
            Expanded(flex: 3, child: _buildMiniRangeInput(sphFrom, sphTo!)),
            const SizedBox(width: 2),
            Expanded(flex: 3, child: _buildMiniRangeInput(cylFrom!, cylTo!)),
            const SizedBox(width: 2),
            Expanded(flex: 3, child: _buildTableInput(axis!, height: 78)),
            const SizedBox(width: 2),
            if (addFrom != null) ...[
              Expanded(flex: 3, child: _buildMiniRangeInput(addFrom, addTo!)),
              const SizedBox(width: 2),
            ],
          ],
          Expanded(flex: 2, child: _buildTableInput(qty, isQty: true, height: 78)),
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
                  _buildPowerStrategySelector(),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
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
                      if (_selectedCategory == 'Lens') {
                        return !isFr && cat.contains('lens') && !cat.contains('contact') && _matchesStrategy(i);
                      }
                      if (_selectedCategory == 'Frame') return isFr;
                      if (_selectedCategory == 'Contact Lens') {
                        return cat.contains('contact') && _matchesStrategy(i);
                      }
                      if (_selectedCategory == 'Solutions') return cat.contains('solution');
                      return true;
                    }).map((i) {
                      final double stock = double.tryParse(i['stockQty']?.toString() ?? '0') ?? 0.0;
                      final itemName = i['itemName'] ?? 'Unknown Item';
                      return DropdownMenuItem(
                        value: i['id']?.toString() ?? i['_id']?.toString(),
                        child: Text(
                           "$itemName (Qty: ${stock.toInt()})", 
                           overflow: TextOverflow.ellipsis,
                           maxLines: 1,
                           style: TextStyle(
                             fontSize: 13,
                             color: stock <= 0 ? Colors.red[700] : Colors.black87,
                             fontWeight: stock <= 0 ? FontWeight.bold : FontWeight.normal
                           )
                        ),
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

                  // 🏪 SMART PROCUREMENT: Out of Stock & Vendor Back-Order Injection
                  Builder(
                    builder: (context) {
                      if (_selectedItem == null || _selectedItemId == null) return const SizedBox();
                      final double stock = double.tryParse(_selectedItem!['stockQty']?.toString() ?? '0') ?? 0.0;
                      if (stock > 0) return const SizedBox();
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.red[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('⚠️ OUT OF STOCK!', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.red[900], fontSize: 13)),
                                      const SizedBox(height: 2),
                                      Text('This item has 0 stock. Please select a Vendor above to place a restock back-order.', style: TextStyle(color: Colors.red[800], fontSize: 11)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // The Elite Vendor Procurement Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft, 
                                end: Alignment.bottomRight, 
                                colors: [const Color(0xFF0D1B2A), Colors.indigo[900]!]
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.blueAccent.withOpacity(0.5), width: 1.5),
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.local_shipping_outlined, color: Colors.amber[400], size: 20),
                                    const SizedBox(width: 8),
                                    const Text('VENDOR RESTOCK PLANNER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.8)),
                                  ],
                                ),
                                const Divider(color: Colors.white24, height: 20),
                                
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.storefront_outlined, color: Colors.amberAccent, size: 18),
                                      const SizedBox(width: 8),
                                      const Text('Assigned Vendor (Lab): ', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                                      Expanded(
                                        child: Builder(
                                          builder: (context) {
                                            final vendor = _vendors.firstWhere(
                                              (v) => (v['id']?.toString() ?? v['_id']?.toString()) == _selectedVendorId,
                                              orElse: () => {},
                                            );
                                            final vName = vendor['name'] ?? '⚠️ NOT SELECTED (Select Above)';
                                            return Text(
                                              vName, 
                                              style: TextStyle(
                                                color: _selectedVendorId == null ? Colors.amberAccent : Colors.white, 
                                                fontWeight: FontWeight.w900, 
                                                fontSize: 12
                                              ),
                                              textAlign: TextAlign.end,
                                              overflow: TextOverflow.ellipsis,
                                            );
                                          }
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Customer Qty', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            width: double.infinity,
                                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                                            child: Builder(
                                              builder: (context) {
                                                final cQty = (_isRightSelected ? (int.tryParse(_rQtyController.text) ?? 1) : 0) + 
                                                            (_isLeftSelected ? (int.tryParse(_lQtyController.text) ?? 1) : 0);
                                                return Text('$cQty Pc${cQty > 1 ? "s" : ""}', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w900));
                                              }
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Restock Qty (Vendor)', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                          const SizedBox(height: 4),
                                          SizedBox(
                                            height: 38,
                                            child: TextFormField(
                                              controller: _vendorRestockQtyController,
                                              keyboardType: TextInputType.number,
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                              textAlign: TextAlign.center,
                                              decoration: InputDecoration(
                                                filled: true,
                                                fillColor: Colors.white.withOpacity(0.15),
                                                contentPadding: EdgeInsets.zero,
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white38)),
                                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white38)),
                                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.amber, width: 1.5)),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      );
                    }
                  ),

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
                      _buildPowerStrategySelector(),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
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
                          if (_selectedCategory == 'Lens') {
                            return !isFr && cat.contains('lens') && !cat.contains('contact') && _matchesStrategy(i);
                          }
                          if (_selectedCategory == 'Frame') return isFr;
                          if (_selectedCategory == 'Contact Lens') {
                            return cat.contains('contact') && _matchesStrategy(i);
                          }
                          if (_selectedCategory == 'Solutions') return cat.contains('solution');
                          return true;
                        }).map((i) {
                          final double stock = double.tryParse(i['stockQty']?.toString() ?? '0') ?? 0.0;
                          final itemName = i['itemName'] ?? 'Unknown Item';
                          return DropdownMenuItem(
                            value: i['id']?.toString() ?? i['_id']?.toString(),
                            child: Text(
                               "$itemName (Qty: ${stock.toInt()})", 
                               overflow: TextOverflow.ellipsis,
                               maxLines: 1,
                               style: TextStyle(
                                 fontSize: 13,
                                 color: stock <= 0 ? Colors.red[700] : Colors.black87,
                                 fontWeight: stock <= 0 ? FontWeight.bold : FontWeight.normal
                               )
                            ),
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
          SizedBox(width: 110, child: Center(child: Text('ITEM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)))),
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
          SizedBox(width: 110, child: Center(child: Text(_itemNameController.text.isNotEmpty ? _itemNameController.text : 'New Item', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blueGrey), overflow: TextOverflow.ellipsis))),
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

  Widget _buildTableInput(TextEditingController controller, {bool isQty = false, double height = 36, String? hint}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 2, offset: const Offset(0, 1)),
        ],
      ),
      child: Center(
        child: TextFormField(
          controller: controller,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
          keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: TextStyle(fontSize: 9, color: Colors.grey[400], letterSpacing: 0.5),
            contentPadding: EdgeInsets.symmetric(vertical: height > 40 ? (height - 16)/2 : 10), // Dynamically center
            border: InputBorder.none, // Clean look, no internal border
            focusedBorder: const OutlineInputBorder(
               borderSide: BorderSide(color: Color(0xFFD4AF37), width: 1.5), // Gold highlight on focus
               borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
          onChanged: (_) {
             if (!isQty) _calculateTotalPrice(); // Optimization: Only recalc if needed, but safe to call
             setState(() {});
          },
        ),
      ),
    );
  }

  Widget _buildMiniRangeInput(TextEditingController from, TextEditingController to) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTableInput(from, hint: 'FROM', height: 36),
        const SizedBox(height: 6),
        _buildTableInput(to, hint: 'TO', height: 36),
      ],
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
          SizedBox(width: 110, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Text(item['itemName'] ?? 'Item', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.indigo), overflow: TextOverflow.ellipsis, textAlign: TextAlign.center))),
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
        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey),
        prefixText: '₹ ',
        prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      onChanged: (_) {
        setState(() => _calculateTotalPrice());
      },
    );
  }

  Widget _buildPricingAndActions({String buttonLabel = 'Add to Order', VoidCallback? onButtonPressed}) {
    final balance = _totalPrice - (double.tryParse(_advancePaidController.text) ?? 0.0);
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue[50]?.withOpacity(0.5) ?? Colors.blue[50],
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.blue[100]!, width: 1),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: R Eye Price & L Eye Price Symmetrical Row
          Row(
            children: [
              Expanded(child: _buildEditablePriceField('R Eye Price', _rEyePriceController)),
              const SizedBox(width: 12),
              Expanded(child: _buildEditablePriceField('L Eye Price', _lEyePriceController)),
            ],
          ),
          const SizedBox(height: 12),

          // Row 2: Delivery Date & Remarks
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _buildDeliveryDateField()),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: TextFormField(
                  controller: _remarksController,
                  maxLines: 1,
                  decoration: InputDecoration(
                    labelText: 'REMARKS',
                    labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Row 3: Modern Total Summary Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TOTAL PRICE', style: TextStyle(color: Colors.grey[500], fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                      const SizedBox(height: 2),
                      Text(
                        '₹ ${_totalPrice.toStringAsFixed(2)}', 
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: balance > 0 ? Colors.red[50] : Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'BALANCE: ₹${balance.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: balance > 0 ? Colors.red[700] : Colors.green[700]),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: _buildEditablePriceField('ADVANCE PAID', _advancePaidController),
                ),
              ],
            ),
          ),
          
          if (double.tryParse(_advancePaidController.text) != null && (double.tryParse(_advancePaidController.text) ?? 0.0) > 0) ...[
            const SizedBox(height: 16),
            Text('ADVANCE PAYMENT MODE', style: TextStyle(color: Colors.grey[600], fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildPaymentMethodChip('Cash', Icons.payments_outlined, _selectedPaymentMethod, (val) {
                  setState(() => _selectedPaymentMethod = val);
                }),
                _buildPaymentMethodChip('Card', Icons.credit_card_outlined, _selectedPaymentMethod, (val) {
                  setState(() => _selectedPaymentMethod = val);
                }),
                _buildPaymentMethodChip('UPI', Icons.qr_code_scanner_outlined, _selectedPaymentMethod, (val) {
                  setState(() => _selectedPaymentMethod = val);
                }),
                _buildPaymentMethodChip('Razorpay', Icons.payment_rounded, _selectedPaymentMethod, (val) {
                  setState(() => _selectedPaymentMethod = val);
                }),
              ],
            ),
          ],
          const SizedBox(height: 20),

          // Row 4: Primary Symmetrical Buttons (Order Save & Reset)
          Row(
            children: [
              Expanded(
                flex: 5,
                child: _buildActionButton(buttonLabel, onButtonPressed),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: _buildResetButton(),
              ),
            ],
          ),
        ],
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
                // Keep the internal controller in sync with our main controller safely after build completes
                if (controller.text != _customerNameController.text) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    controller.text = _customerNameController.text;
                  });
                }

                return GestureDetector(
                  onDoubleTap: () {
                    focusNode.unfocus();
                  },
                  child: TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    onChanged: (val) {
                      _customerNameController.text = val;
                    },
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
              const SizedBox(height: 16),
              
              // 1. GORGEOUS CUSTOMER BUDGET INTELLIGENCE BANNER
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.psychology, color: Colors.amberAccent, size: 22),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'BUYING INSIGHTS & BUDGET',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              Text(
                                'Smart analysis of previous purchases',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 8,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _maxFrameSpent >= 3000 ? Colors.redAccent.withOpacity(0.2) : Colors.greenAccent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _maxFrameSpent >= 3000 ? Colors.redAccent : Colors.greenAccent,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _maxFrameSpent >= 4000 
                                ? '🏆 VIP CUSTOMER' 
                                : _maxFrameSpent >= 1500 
                                    ? '💎 MID-PREMIUM' 
                                    : '⚡ BUDGET CLASS',
                            style: TextStyle(
                              color: _maxFrameSpent >= 3000 ? Colors.redAccent[100] : Colors.greenAccent[100],
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(color: Colors.white24, height: 1, thickness: 1),
                    ),
                    
                    // Symmetrical Metric Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildInsightMetric('Total Spent', '₹${_totalSpent.toStringAsFixed(0)}'),
                        _buildInsightMetric('Max Frame Cost', _maxFrameSpent > 0 ? '₹${_maxFrameSpent.toStringAsFixed(0)}' : 'N/A'),
                        _buildInsightMetric('Max Lens Cost', _maxLensSpent > 0 ? '₹${_maxLensSpent.toStringAsFixed(0)}' : 'N/A'),
                      ],
                    ),
                    
                    if (_maxFrameSpent > 0 || _maxLensSpent > 0) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.verified, color: Colors.amberAccent, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '👉 RECOMMENDED FRAME STRATEGY:',
                                    style: TextStyle(
                                      color: Colors.amberAccent[100],
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Offer frames priced above ₹${_maxFrameSpent.toStringAsFixed(0)} (e.g. ₹${(_maxFrameSpent * 1.5).toStringAsFixed(0)} - ₹${(_maxFrameSpent * 4.0).toStringAsFixed(0)}). Avoid cheap frames as this customer has a higher purchasing capability!',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      height: 1.3,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.history, size: 14, color: Colors.blue),
                  const SizedBox(width: 6),
                  const Text(
                    'DETAILED PURCHASE HISTORY',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue, letterSpacing: 1),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // 2. TALLER, RICH DETAILS HORIZONTAL CARDS LIST
              SizedBox(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _customerHistory.length,
                  itemBuilder: (context, index) {
                    final order = _customerHistory[index];
                    final String rawStatus = order['status']?.toString() ?? 'Pending';
                    final String statusStr = rawStatus.toUpperCase();
                    
                    Color badgeColor = Colors.orange;
                    if (statusStr.contains('DELIVERED') || statusStr.contains('COMPLETED')) {
                      badgeColor = Colors.green;
                    } else if (statusStr.contains('READY')) {
                      badgeColor = Colors.blue;
                    } else if (statusStr.contains('PROGRESS')) {
                      badgeColor = Colors.purple;
                    }
                    
                    final items = order['items'] as List? ?? [];
                    final String itemsSummary = items.map((it) {
                      final name = it['description'] ?? it['itemName'] ?? 'Item';
                      final price = double.tryParse(it['unitPrice']?.toString() ?? it['salePrice']?.toString() ?? it['lineTotal']?.toString() ?? '0') ?? 0.0;
                      return "• $name (₹${price.toStringAsFixed(0)})";
                    }).join('\n');
                    
                    return GestureDetector(
                      onTap: () => _showInvoiceDetailsModal(order),
                      child: Container(
                        width: 190,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.blue.shade100, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withValues(alpha: 0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    order['date'] ?? '',
                                    style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: badgeColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    rawStatus.toUpperCase(),
                                    style: TextStyle(color: badgeColor, fontSize: 7, fontWeight: FontWeight.w900),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹${order['amount']}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.blue),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              order['sn'] ?? 'JC-XXX',
                              style: TextStyle(fontSize: 8, color: Colors.grey[500], fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            
                            // Rich itemized summary inside the card!
                            Expanded(
                              child: SingleChildScrollView(
                                physics: const NeverScrollableScrollPhysics(),
                                child: Text(
                                  itemsSummary.isNotEmpty ? itemsSummary : '• Custom Optics Order',
                                  style: TextStyle(fontSize: 8, color: Colors.grey[700], height: 1.3, fontWeight: FontWeight.w500),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.receipt_long_outlined, size: 10, color: Colors.blue),
                                const SizedBox(width: 4),
                                Text(
                                  'View Details',
                                  style: TextStyle(fontSize: 9, color: Colors.blue[800], fontWeight: FontWeight.bold),
                                ),
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
              onChanged: (val) async {
                final cleanedSearch = val.replaceAll(' ', '').replaceAll('+91', '');
                if (cleanedSearch.length >= 10) {
                  final results = await _customerService.searchCustomers(val);
                  final match = results.firstWhere(
                    (c) {
                      final cleanedMobile = c['mobile'].toString().replaceAll(' ', '').replaceAll('+91', '');
                      return cleanedMobile == cleanedSearch;
                    },
                    orElse: () => {},
                  );
                  if (match.isNotEmpty) {
                    setState(() {
                      _selectedCustomerId = match['_id']?.toString() ?? match['id']?.toString();
                      _customerNameController.text = match['name'] ?? '';
                      _addressController.text = match['address'] ?? '';
                      _dobController.text = match['dob'] ?? '';
                      _shouldSaveCustomer = false; // Existing customer
                    });
                    _fetchCustomerHistory(match['mobile'], name: match['name']);
                  }
                }
              },
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

  Widget _buildInsightMetric(String label, String value) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: Colors.amberAccent, fontSize: 13, fontWeight: FontWeight.w900),
        ),
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
            
            // Vendor Selection - Conditional Visibility
            if (_isVendorRequired()) ...[
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
                          // Do not reset _selectedItemId here, to preserve pre-loaded scanned items!
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
            ],
            
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
              _buildPowerStrategySelector(),
              DropdownButtonFormField<String>(
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Select Lens *', border: OutlineInputBorder(), isDense: true),
                value: _selectedItemId,
                items: _items.where((i) => i['isFrame'] != true && _matchesStrategy(i)).map((i) {
                  final double stock = double.tryParse(i['stockQty']?.toString() ?? '0') ?? 0.0;
                  return DropdownMenuItem(
                    value: i['id']?.toString() ?? i['_id']?.toString(),
                    child: Text(
                       "${i['itemName'] ?? ''} (Qty: ${stock.toInt()})", 
                       overflow: TextOverflow.ellipsis,
                       maxLines: 1,
                       style: TextStyle(
                         fontSize: 13,
                         color: stock <= 0 ? Colors.red[700] : Colors.black87,
                         fontWeight: stock <= 0 ? FontWeight.bold : FontWeight.normal
                       )
                    ),
                  );
                }).toList(),
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
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Select Frame *', border: OutlineInputBorder(), isDense: true),
                value: _selectedFrameId,
                items: _items.where((i) => i['isFrame'] == true).map((i) {
                  final double stock = double.tryParse(i['stockQty']?.toString() ?? '0') ?? 0.0;
                  return DropdownMenuItem(
                    value: i['id']?.toString() ?? i['_id']?.toString(),
                    child: Text(
                       "${i['itemName'] ?? ''} (Qty: ${stock.toInt()})", 
                       overflow: TextOverflow.ellipsis,
                       maxLines: 1,
                       style: TextStyle(
                         fontSize: 13,
                         color: stock <= 0 ? Colors.red[700] : Colors.black87,
                         fontWeight: stock <= 0 ? FontWeight.bold : FontWeight.normal
                       )
                    ),
                  );
                }).toList(),
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
    final String rawStatus = order['status']?.toString() ?? 'Pending';
    final List<dynamic> rawItems = order['items'] as List? ?? [];
    
    // Map payments from the backend format if available
    List<dynamic> paymentsList = [];
    if (order['raw'] != null && order['raw']['payments'] != null) {
      paymentsList = order['raw']['payments'] as List? ?? [];
    }

    // Build the exact invoice shape required by _showNativeInvoiceDialog
    final Map<String, dynamic> mappedCard = {
      'billNo': order['sn'] ?? order['invoice'] ?? 'JC-XXXX',
      'customerId': order['customer'] ?? 'Walk-In',
      'status': rawStatus.toUpperCase(),
      'totalAmount': double.tryParse(order['amount']?.toString() ?? '0') ?? 0.0,
      'paidAmount': double.tryParse(order['paidAmount']?.toString() ?? '0') ?? 0.0,
      'dueAmount': double.tryParse(order['dueAmount']?.toString() ?? '0') ?? 0.0,
      'createdAt': order['raw']?['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
      'customer': {
        'fullName': order['customer'] ?? 'Customer',
        'phone': order['mobile'] ?? '',
      },
      'items': rawItems.map((e) => {
        'description': e['description'] ?? e['itemName'] ?? 'Product',
        'quantity': double.tryParse(e['quantity']?.toString() ?? e['qty']?.toString() ?? '1')?.toInt() ?? 1,
        'lineTotal': double.tryParse((e['lineTotal'] ?? e['unitPrice'] ?? '0').toString()) ?? 0.0,
        'sph': e['sph']?.toString() ?? '',
        'cyl': e['cyl']?.toString() ?? '',
        'eye': e['eye']?.toString() ?? '',
      }).toList(),
      'payments': paymentsList,
    };

    _showNativeInvoiceDialog(mappedCard, fromHistory: true);
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

  // 🔄 INVOICE WORKFLOW INITIATOR
  void _triggerInvoiceWorkflow(String billNo, double netTotal, double alreadyPaid, List<dynamic> items) {
    final Map<String, dynamic> invoiceCard = {
      'billNo': billNo,
      'customerId': _customerNameController.text.isNotEmpty ? _customerNameController.text : 'Unnamed Customer',
      'status': 'SAVED',
      'totalAmount': netTotal,
      'paidAmount': alreadyPaid,
      'dueAmount': netTotal - alreadyPaid,
      'createdAt': DateTime.now().toIso8601String(),
      'customer': {
        'fullName': _customerNameController.text.isNotEmpty ? _customerNameController.text : 'Customer',
        'phone': _mobileController.text,
      },
      'items': items.map((e) => {
        'description': e['itemName'] ?? 'Product',
        'quantity': double.tryParse(e['qty']?.toString() ?? '1')?.toInt() ?? 1,
        'lineTotal': double.tryParse(e['totalAmount']?.toString() ?? '0') ?? 0.0,
        'sph': e['sph'] ?? '',
        'cyl': e['cyl'] ?? '',
        'eye': e['eye'] ?? '',
      }).toList(),
    };

    _showNativeInvoiceDialog(invoiceCard);
  }

  // 🧾 RETAIL INVOICE VIEWER & SHARING DIALOG
  void _showNativeInvoiceDialog(dynamic card, {bool fromHistory = false}) {
    final String billNoRaw = card['billNo'] ?? 'No Bill';
    // 💎 Generate premium, user-friendly formatted receipt number
    final String billNo = billNoRaw.length > 10 
        ? 'INV-${billNoRaw.substring(billNoRaw.length - 6).toUpperCase()}' 
        : billNoRaw;
    final String customerId = card['customerId'] ?? 'Walk-In';
    final String status = card['status'] ?? 'SAVED';
    final double totalAmount = double.tryParse(card['totalAmount']?.toString() ?? '0') ?? 0.0;
    final double paidAmount = double.tryParse(card['paidAmount']?.toString() ?? '0') ?? 0.0;
    final double dueAmount = double.tryParse(card['dueAmount']?.toString() ?? '0') ?? 0.0;
    final String dateStr = card['createdAt'] != null 
        ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(card['createdAt'])) 
        : 'N/A';

    final itemsList = card['items'] as List? ?? [];

    showDialog(
      context: context,
      barrierDismissible: false, // Force user to acknowledge invoice before returning
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, spreadRadius: 5)],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Banner
                const Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Color(0xFFE8EAF6),
                        child: Icon(Icons.receipt_long_rounded, color: Color(0xFF1A237E), size: 32),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'RETAIL LENS OPTICALS',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 1.2, color: Color(0xFF1A237E)),
                      ),
                      Text(
                        'Premium Lens & Eyewear Solutions',
                        style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                _buildDottedLine(),
                const SizedBox(height: 16),

                // Metadata Grid
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Invoice No: $billNo', 
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: dueAmount > 0 ? Colors.amber.withOpacity(0.15) : Colors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        dueAmount > 0 ? 'PARTIAL PAID' : 'PAID IN FULL',
                        style: TextStyle(
                          color: dueAmount > 0 ? Colors.orange[800] : Colors.green[800],
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Customer: $customerId', style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Date Issued: $dateStr', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                
                const SizedBox(height: 16),
                _buildDottedLine(),
                const SizedBox(height: 16),

                // Items
                const Text('BILLED ITEMS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF1A237E), letterSpacing: 1.1)),
                const SizedBox(height: 12),
                ...itemsList.map((item) {
                  final desc = item['description'] ?? 'Unnamed Item';
                  final qty = item['quantity'] ?? 1;
                  final total = double.tryParse(item['lineTotal']?.toString() ?? '0') ?? 0.0;
                  final powerInfo = (item['sph'] != null && item['sph'].toString().isNotEmpty) 
                      ? 'SPH: ${item['sph']} | CYL: ${item['cyl']} | Eye: ${item['eye']}' 
                      : '';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text('$desc', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                            Text('x$qty', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(width: 12),
                            Text('₹${total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF1A237E))),
                          ],
                        ),
                        if (powerInfo.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Text(powerInfo, style: TextStyle(color: Colors.grey[700], fontSize: 11, fontStyle: FontStyle.italic)),
                          ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 16),
                _buildDottedLine(),
                const SizedBox(height: 16),

                // Payment Summary Grid
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.blue[50]?.withOpacity(0.3), borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Gross Total:', style: TextStyle(fontSize: 13, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                          Text('₹${totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Amount Settled:', style: TextStyle(fontSize: 13, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                          Text('₹${paidAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.green)),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('BALANCE DUE:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF1A237E))),
                          Text(
                            '₹${dueAmount.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: dueAmount > 0 ? Colors.redAccent : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                const Center(
                  child: Text('🎉 Thank you for your business! 👓✨', style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
                ),
                const SizedBox(height: 24),

                // Interactive CTA Actions
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _launchWhatsApp(card, 'Invoice'),
                        icon: const Icon(Icons.share, color: Colors.white, size: 18),
                        label: const Text('SHARE INVOICE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                          elevation: 4,
                          shadowColor: Colors.green.withOpacity(0.4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Close Modal
                          if (!fromHistory) {
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const JobCardsListScreen()));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: fromHistory ? const Color(0xFF039BE5) : const Color(0xFF1A237E),
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          fromHistory ? 'Close Receipt' : 'DONE & CLOSE',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDottedLine() {
    return Row(
      children: List.generate(
        40,
        (index) => Expanded(
          child: Container(
            color: index % 2 == 0 ? Colors.transparent : Colors.grey[300],
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Future<void> _launchWhatsApp(dynamic card, String status) async {
    final customer = card['customer'] as Map? ?? {};
    final String name = customer['fullName'] ?? card['customerId'] ?? 'Valued Customer';
    final String mobile = customer['phone'] ?? _mobileController.text;
    final String billNo = card['billNo'] ?? 'N/A';
    
    if (mobile.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot share: Customer phone number is missing!'), backgroundColor: Colors.red),
      );
      return;
    }

    final items = card['items'] as List? ?? [];
    final double total = double.tryParse(card['totalAmount']?.toString() ?? '0') ?? 0.0;
    final double paid = double.tryParse(card['paidAmount']?.toString() ?? '0') ?? 0.0;
    final double due = double.tryParse(card['dueAmount']?.toString() ?? '0') ?? 0.0;
    
    final String itemsStr = items.map((it) {
      final desc = it['description'] ?? it['itemName'] ?? 'Eyewear Item';
      final qty = it['quantity'] ?? 1;
      final price = it['lineTotal'] ?? 0;
      return "• $desc (x$qty) - ₹$price";
    }).join('\n');

    final String message = "*RETAIL LENS OPTICALS*\n"
        "Premium Lens & Eyewear Solutions\n\n"
        "Hello $name,\n"
        "Thank you for your visit! Here are your invoice details for Bill No: *$billNo* 📄✨\n\n"
        "*ITEMS ORDERED:*\n$itemsStr\n\n"
        "*PAYMENT SUMMARY:*\n"
        "• Total Amount: ₹${total.toStringAsFixed(0)}\n"
        "• Amount Paid: ₹${paid.toStringAsFixed(0)}\n"
        "*• DUE BALANCE: ₹${due.toStringAsFixed(0)}*\n\n"
        "We appreciate your trust in Retail Lens! We will notify you once your custom specs are ready for collection. 👓✨";
    
    String cleanMobile = mobile.replaceAll(RegExp(r'\D'), '');
    if (cleanMobile.length == 10) cleanMobile = "91$cleanMobile";

    final Uri url = Uri.parse("https://wa.me/$cleanMobile?text=${Uri.encodeComponent(message)}");

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch WhatsApp client.';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening WhatsApp: $e'), backgroundColor: Colors.red),
      );
    }
  }
}


