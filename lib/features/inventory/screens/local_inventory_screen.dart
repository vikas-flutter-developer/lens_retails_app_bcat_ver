import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' hide Border;
import '../services/inventory_service.dart';
import '../../pos/screens/barcode_scanner_screen.dart';
import '../../common/screens/qr_scanner_hub_screen.dart';
import '../../orders/services/master_data_service.dart';
import '../../orders/screens/vendor_master_screen.dart';

class LocalInventoryScreen extends StatefulWidget {
  const LocalInventoryScreen({super.key});

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
  // Power Filter State
  String _fSearchMode = 'Any'; 
  bool _fREnabled = false;
  String? _fRSphFrom, _fRSphTo, _fRCylFrom, _fRCylTo, _fRAxis;
  bool _fLEnabled = false;
  String? _fLSphFrom, _fLSphTo, _fLCylFrom, _fLCylTo, _fLAxis;

  bool _isPowerFiltered() =>
      _fREnabled || _fLEnabled || _fSearchMode != 'Any';

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

  List<Map<String, dynamic>> _getFilteredItems(
      List<Map<String, dynamic>> items) {
    try {
      final List<Map<String, dynamic>> filtered = items.where((item) {
        // Category Filter
        final String itemCategory =
            (item['kind'] ?? item['groupName'] ?? item['category'] ?? '')
                .toString()
                .toLowerCase();
        final String selectedCat = _selectedCategory.toLowerCase();

        bool matchesCategory = true;
        if (selectedCat != 'all') {
          if (selectedCat == 'frames' && itemCategory == 'frame') {
            matchesCategory = true;
          } else if (selectedCat == 'lenses' && itemCategory == 'lens') {
            matchesCategory = true;
          } else if (selectedCat == 'contact lenses' &&
              itemCategory == 'accessory' &&
              (item['name'] ?? '').toString().toLowerCase().contains('lens')) {
            matchesCategory = true;
          } else if (selectedCat == 'solutions' &&
              itemCategory == 'accessory' &&
              (item['name'] ?? '').toString().toLowerCase().contains('sol')) {
            matchesCategory = true;
          } else if (selectedCat == 'accessories' &&
              itemCategory == 'accessory') {
            matchesCategory = true;
          } else {
            matchesCategory = itemCategory == selectedCat;
          }
        }

        // Search Filter
        final String query = _barcodeController.text.toLowerCase();
        final String itemName =
            (item['name'] ?? item['itemName'] ?? '').toString().toLowerCase();
        final String itemSku = (item['sku'] ?? '').toString().toLowerCase();
        final String powerStr =
            _formatPowerSpecs(item['powerSpecs']).toLowerCase();

        final bool matchesSearch = query.isEmpty ||
            itemName.contains(query) ||
            itemSku.contains(query) ||
            powerStr.contains(query);

        // Date Filter
        bool matchesDate = true;
        if (_startDate != null || _endDate != null) {
          final String? dateStr =
              item['receivedDate'] ?? item['createdAt']?.toString();
          if (dateStr != null && dateStr.isNotEmpty) {
            try {
              final DateTime arrivalDate = DateTime.parse(dateStr);

              if (_startDate != null) {
                final start = DateTime(
                    _startDate!.year, _startDate!.month, _startDate!.day);
                if (arrivalDate.isBefore(start)) matchesDate = false;
              }
              if (_endDate != null) {
                final end = DateTime(
                    _endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
                if (arrivalDate.isAfter(end)) matchesDate = false;
              }
            } catch (_) {
              matchesDate = false;
            }
          } else {
            matchesDate = false;
          }
        }

        // Power Filters
        bool matchesPower = true;
        if (_isPowerFiltered()) {
          final specs = item['powerSpecs'];
          if (specs == null || specs is! Map || specs.isEmpty) {
            matchesPower = false;
          } else {
            bool checkEye(dynamic eyeData, bool enabled, String? sF, String? sT,
                String? cF, String? cT, String? ax) {
              if (!enabled) return true;
              if (eyeData == null || eyeData is! Map) return false;

              final bool sOk = _doesRangeOverlap(
                  sF, sT, eyeData['sphFrom'], eyeData['sphTo']);
              final bool cOk = _doesRangeOverlap(
                  cF, cT, eyeData['cylFrom'], eyeData['cylTo']);
              bool aOk = true;
              if (ax != null && ax.isNotEmpty) {
                final String dbAx = (eyeData['axis'] ?? '').toString().trim();
                aOk = dbAx.contains(ax);
              }
              return sOk && cOk && aOk;
            }

            final bool rOk = checkEye(specs['rightEye'], _fREnabled, _fRSphFrom,
                _fRSphTo, _fRCylFrom, _fRCylTo, _fRAxis);
            final bool lOk = checkEye(specs['leftEye'], _fLEnabled, _fLSphFrom,
                _fLSphTo, _fLCylFrom, _fLCylTo, _fLAxis);

            bool modeOk = true;
            if (_fSearchMode != 'Any') {
              final r = specs['rightEye'];
              final l = specs['leftEye'];
              final bool hasR = r != null &&
                  r is Map &&
                  ((r['sphFrom']?.toString() ?? '').isNotEmpty ||
                      (r['sphTo']?.toString() ?? '').isNotEmpty);
              final bool hasL = l != null &&
                  l is Map &&
                  ((l['sphFrom']?.toString() ?? '').isNotEmpty ||
                      (l['sphTo']?.toString() ?? '').isNotEmpty);

              if (_fSearchMode == 'Single R') {
                modeOk = hasR && !hasL;
              } else if (_fSearchMode == 'Single L') {
                modeOk = !hasR && hasL;
              } else if (_fSearchMode == 'Both (Same)') {
                if (!hasR || !hasL) {
                  modeOk = false;
                } else {
                  final String rs =
                      '${r['sphFrom']}-${r['sphTo']}-${r['cylFrom']}-${r['cylTo']}-${r['axis']}';
                  final String ls =
                      '${l['sphFrom']}-${l['sphTo']}-${l['cylFrom']}-${l['cylTo']}-${l['axis']}';
                  modeOk = rs == ls;
                }
              } else if (_fSearchMode == 'Both (Diff)') {
                if (!hasR || !hasL) {
                  modeOk = false;
                } else {
                  final String rs =
                      '${r['sphFrom']}-${r['sphTo']}-${r['cylFrom']}-${r['cylTo']}-${r['axis']}';
                  final String ls =
                      '${l['sphFrom']}-${l['sphTo']}-${l['cylFrom']}-${l['cylTo']}-${l['axis']}';
                  modeOk = rs != ls;
                }
              }
            }

            matchesPower = rOk && lOk && modeOk;
          }
        }

        return matchesCategory && matchesSearch && matchesDate && matchesPower;
      }).toList();

      // SORTING LOGIC
      filtered.sort((a, b) {
        final DateTime dateA = DateTime.tryParse(
                (a['createdAt'] ?? a['receivedDate'] ?? '').toString()) ??
            DateTime(1900);
        final DateTime dateB = DateTime.tryParse(
                (b['createdAt'] ?? b['receivedDate'] ?? '').toString()) ??
            DateTime(1900);

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

  Future<void> _orderViaWhatsApp(Map<String, dynamic> item, int qty) async {
    final String sku = (item['sku'] ?? 'N/A').toString();
    final String name = (item['name'] ?? item['itemName'] ?? 'Unknown Item').toString();
    final dynamic powerSpecs = item['powerSpecs'];
    
    String message = "Hello, I would like to order $qty quantity of $name.\n\n";
    message += "SKU: $sku\n";
    
    final String powerStr = _formatPowerSpecs(powerSpecs);
    if (powerStr.isNotEmpty) {
      message += "Power Details: $powerStr\n";
    }
    
    message += "\nPlease confirm availability and price.";

    // Find vendor phone
    String? vendorPhone;
    if (item['vendorId'] != null) {
      final v = _vendors.firstWhere(
        (ven) => (ven['id']?.toString() == item['vendorId']?.toString()),
        orElse: () => {},
      );
      vendorPhone = v['phone']?.toString();
    }
    
    if (vendorPhone == null || vendorPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No phone number found for this vendor! Please update vendor contact first.'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    // Sanitize phone number (remove spaces, etc.)
    vendorPhone = vendorPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (vendorPhone.length == 10) {
      vendorPhone = "91$vendorPhone"; // Default to India prefix if 10 digits
    }

    final String url = "https://wa.me/$vendorPhone?text=${Uri.encodeComponent(message)}";
    
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Could not open WhatsApp. Make sure it is installed.'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    super.dispose();
  }

  Future<void> _importFile() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'pdf'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read file data.')),
        );
        return;
      }

      final extension = file.extension?.toLowerCase();
      if (extension == 'pdf') {
        await _importPdf(bytes);
      } else {
        await _importExcel(bytes);
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
  }

  Future<void> _importPdf(Uint8List bytes) async {
    bool hasDialog = false;
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF1A237E)),
        ),
      );
      hasDialog = true;

      final parsedItems = await _inventoryService.parsePdf(bytes);
      
      if (hasDialog) {
        Navigator.pop(context); // Close loading indicator
        hasDialog = false;
      }

      if (parsedItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No valid items could be parsed from the PDF.')),
        );
        return;
      }

      // Show preview dialog
      _showImportPreviewDialog(parsedItems);
    } catch (e) {
      if (hasDialog) {
        Navigator.pop(context); // Close loading indicator
        hasDialog = false;
      }
      debugPrint('Error parsing PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error parsing PDF: $e')),
      );
    }
  }

  Future<void> _importExcel(Uint8List bytes) async {
    bool hasDialog = false;
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF1A237E)),
        ),
      );
      hasDialog = true;

      final excel = Excel.decodeBytes(bytes);
      
      if (hasDialog) {
        Navigator.pop(context); // Close loading indicator
        hasDialog = false;
      }

      if (excel.tables.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Excel file is empty.')),
        );
        return;
      }

      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName];
      if (sheet == null || sheet.maxRows <= 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No data rows found in Excel sheet.')),
        );
        return;
      }

      // Find headers
      int nameIdx = 1;
      int grpIdx = 2;
      int barcodeIdx = 6;
      int qtyIdx = 4; // stock in hand
      int purIdx = 8;
      int saleIdx = 9;

      bool headersFound = false;
      // Search first 5 rows for headers
      for (int r = 0; r < math.min(sheet.maxRows, 6); r++) {
        final row = sheet.rows[r];
        bool hasName = false;
        bool hasBarcode = false;
        for (int c = 0; c < row.length; c++) {
          final val = row[c]?.value?.toString().toLowerCase() ?? '';
          if (val.contains('prod name') || val == 'name' || val == 'product name') {
            nameIdx = c;
            hasName = true;
          } else if (val.contains('prod grp') || val == 'group' || val == 'category') {
            grpIdx = c;
          } else if (val == 'barcode' || val == 'sku' || val == 'code') {
            barcodeIdx = c;
            hasBarcode = true;
          } else if (val.contains('stock in_hand') || val.contains('opng stock') || val == 'qty' || val == 'quantity') {
            qtyIdx = c;
          } else if (val.contains('pur prc') || val.contains('purchase') || val == 'cost') {
            purIdx = c;
          } else if (val.contains('sale prc') || val.contains('sale price') || val == 'mrp' || val == 'price') {
            saleIdx = c;
          }
        }
        if (hasName || hasBarcode) {
          // Found header row! Start parsing from row r + 1
          headersFound = true;
          break;
        }
      }

      final List<Map<String, dynamic>> parsedItems = [];
      // If we found headers, start after the header row. Otherwise, start from row 0.
      final int startRow = headersFound ? 1 : 0; 

      for (int r = startRow; r < sheet.maxRows; r++) {
        final row = sheet.rows[r];
        if (row.isEmpty) continue;

        // Extract name
        final name = r < sheet.maxRows && nameIdx < row.length 
            ? row[nameIdx]?.value?.toString().trim() ?? '' 
            : '';
        if (name.isEmpty || name.toLowerCase().contains('sadguru') || name.toLowerCase() == 'prod name') {
          // Skip header titles or empty rows
          continue;
        }

        // Extract barcode/SKU
        String sku = r < sheet.maxRows && barcodeIdx < row.length 
            ? row[barcodeIdx]?.value?.toString().trim() ?? '' 
            : '';
        if (sku.isEmpty || sku.toUpperCase() == 'NA') {
          sku = 'GEN-IMPORT-${r}-${DateTime.now().millisecondsSinceEpoch % 100000}';
        }

        // Extract group/kind
        final grp = r < sheet.maxRows && grpIdx < row.length 
            ? row[grpIdx]?.value?.toString().trim().toUpperCase() ?? '' 
            : '';
        String kind = 'ACCESSORY';
        if (grp.contains('FRAME')) {
          kind = 'FRAME';
        } else if (grp.contains('LENS')) {
          kind = 'LENS';
        }

        // Extract qty
        final qtyStr = r < sheet.maxRows && qtyIdx < row.length 
            ? row[qtyIdx]?.value?.toString().trim() ?? '0' 
            : '0';
        final int qty = double.tryParse(qtyStr)?.toInt() ?? 0;

        // Extract prices
        final purStr = r < sheet.maxRows && purIdx < row.length 
            ? row[purIdx]?.value?.toString().trim() ?? '0' 
            : '0';
        final double purchasePrice = double.tryParse(purStr) ?? 0.0;

        final saleStr = r < sheet.maxRows && saleIdx < row.length 
            ? row[saleIdx]?.value?.toString().trim() ?? '0' 
            : '0';
        final double salePrice = double.tryParse(saleStr) ?? 1200.0;

        parsedItems.add({
          'sku': sku,
          'name': name,
          'kind': kind,
          'stockQuantity': qty,
          'salePrice': salePrice,
          'purchasePrice': purchasePrice,
        });
      }

      if (parsedItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No valid items could be parsed from the file.')),
        );
        return;
      }

      // Show preview dialog
      _showImportPreviewDialog(parsedItems);
    } catch (e) {
      if (hasDialog) {
        Navigator.pop(context); // Close loading indicator
        hasDialog = false;
      }
      debugPrint('Error parsing Excel: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error parsing Excel: $e')),
      );
    }
  }

  void _showImportPreviewDialog(List<Map<String, dynamic>> items) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final Set<int> selectedIndices = List.generate(items.length, (index) => index).toSet();
        return StatefulBuilder(
          builder: (builderContext, setState) {
            int totalPcs = 0;
            double totalPurchaseValue = 0.0;
            double totalSaleValue = 0.0;
            int frameCount = 0;
            int lensCount = 0;
            int accessoryCount = 0;

            for (int i = 0; i < items.length; i++) {
              if (!selectedIndices.contains(i)) continue;
              final item = items[i];
              final qty = (item['stockQuantity'] as num?)?.toInt() ?? 0;
              final purPrice = (item['purchasePrice'] as num?)?.toDouble() ?? 0.0;
              final salePrice = (item['salePrice'] as num?)?.toDouble() ?? 0.0;
              final kind = item['kind']?.toString().toUpperCase() ?? 'ACCESSORY';

              totalPcs += qty;
              totalPurchaseValue += (qty * purPrice);
              totalSaleValue += (qty * salePrice);

              if (kind == 'FRAME') {
                frameCount++;
              } else if (kind == 'LENS') {
                lensCount++;
              } else {
                accessoryCount++;
              }
            }

            final double profitMargin = totalSaleValue > 0
                ? ((totalSaleValue - totalPurchaseValue) / totalSaleValue) * 100
                : 0.0;

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: [
                  const Icon(Icons.analytics_outlined, color: Color(0xFF1A237E), size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Import Preview & Analysis',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Review summary analytics before adding to inventory',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.normal),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 500,
                height: 520,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Analysis Cards
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F6FC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E5F5)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              _buildStatCard(
                                title: 'Unique Items',
                                value: '${selectedIndices.length}',
                                icon: Icons.inventory_2_outlined,
                                iconColor: const Color(0xFF1A237E),
                              ),
                              const SizedBox(width: 8),
                              _buildStatCard(
                                title: 'Total Stock',
                                value: '$totalPcs Pcs',
                                icon: Icons.unarchive_outlined,
                                iconColor: const Color(0xFF2E7D32),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildStatCard(
                                title: 'Purchase Value',
                                value: '₹${totalPurchaseValue.toStringAsFixed(0)}',
                                icon: Icons.shopping_bag_outlined,
                                iconColor: const Color(0xFFC62828),
                              ),
                              const SizedBox(width: 8),
                              _buildStatCard(
                                title: 'Est. Revenue',
                                value: '₹${totalSaleValue.toStringAsFixed(0)}',
                                icon: Icons.monetization_on_outlined,
                                iconColor: const Color(0xFFF57C00),
                              ),
                            ],
                          ),
                          if (profitMargin > 0) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.trending_up, color: Color(0xFF2E7D32), size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Estimated Profit Margin: ${profitMargin.toStringAsFixed(1)}%',
                                    style: const TextStyle(
                                      color: Color(0xFF2E7D32),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Category breakdown Chips
                    Row(
                      children: [
                        const Text(
                          'Breakdown: ',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black54),
                        ),
                        if (frameCount > 0) ...[
                          _buildCategoryChip('Frames', frameCount, const Color(0xFFE8EAF6), const Color(0xFF3F51B5)),
                          const SizedBox(width: 6),
                        ],
                        if (lensCount > 0) ...[
                          _buildCategoryChip('Lenses', lensCount, const Color(0xFFE0F2F1), const Color(0xFF009688)),
                          const SizedBox(width: 6),
                        ],
                        if (accessoryCount > 0) ...[
                          _buildCategoryChip('Accessories', accessoryCount, const Color(0xFFFFF3E0), const Color(0xFFFF9800)),
                        ],
                        if (frameCount == 0 && lensCount == 0 && accessoryCount == 0) ...[
                          const Text(
                            'None selected',
                            style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Itemized List Preview',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1A237E)),
                        ),
                        InkWell(
                          onTap: () {
                            setState(() {
                              if (selectedIndices.length == items.length) {
                                selectedIndices.clear();
                              } else {
                                selectedIndices.clear();
                                selectedIndices.addAll(Iterable<int>.generate(items.length));
                              }
                            });
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: selectedIndices.length == items.length
                                    ? true
                                    : (selectedIndices.isEmpty ? false : null),
                                tristate: true,
                                activeColor: const Color(0xFF1A237E),
                                visualDensity: VisualDensity.compact,
                                onChanged: (val) {
                                  setState(() {
                                    if (selectedIndices.length == items.length) {
                                      selectedIndices.clear();
                                    } else {
                                      selectedIndices.clear();
                                      selectedIndices.addAll(Iterable<int>.generate(items.length));
                                    }
                                  });
                                },
                              ),
                              const Text(
                                'Select All',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    
                    // Scrollable Item List
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: items.length,
                            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                            itemBuilder: (context, i) {
                              final item = items[i];
                              final isSelected = selectedIndices.contains(i);
                              return ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                leading: Checkbox(
                                  value: isSelected,
                                  activeColor: const Color(0xFF1A237E),
                                  visualDensity: VisualDensity.compact,
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true) {
                                        selectedIndices.add(i);
                                      } else {
                                        selectedIndices.remove(i);
                                      }
                                    });
                                  },
                                ),
                                title: Text(
                                  item['name'] ?? '',
                                  style: TextStyle(
                                    fontSize: 13, 
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.black : Colors.grey.shade500,
                                    decoration: isSelected ? null : TextDecoration.lineThrough,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  'SKU: ${item['sku'] ?? 'N/A'} • ${item['kind'] ?? 'ACCESSORY'}',
                                  style: TextStyle(
                                    fontSize: 11, 
                                    color: isSelected ? Colors.grey.shade600 : Colors.grey.shade400,
                                  ),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${item['stockQuantity'] ?? 0} Pcs',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold, 
                                        fontSize: 13, 
                                        color: isSelected ? const Color(0xFF1A237E) : Colors.grey.shade400,
                                      ),
                                    ),
                                    Text(
                                      'Pur: ₹${(item['purchasePrice'] as num?)?.toStringAsFixed(0) ?? '0'} • Sale: ₹${(item['salePrice'] as num?)?.toStringAsFixed(0) ?? '0'}',
                                      style: TextStyle(
                                        fontSize: 10, 
                                        color: isSelected ? Colors.black54 : Colors.grey.shade400,
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  setState(() {
                                    if (isSelected) {
                                      selectedIndices.remove(i);
                                    } else {
                                      selectedIndices.add(i);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.only(right: 16, bottom: 16, left: 16),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => Navigator.pop(builderContext),
                        child: const Text('Cancel Import', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A237E),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: selectedIndices.isEmpty
                            ? null
                            : () async {
                                // 1. Close preview dialog using the dialog's context builderContext
                                Navigator.pop(builderContext);
                                
                                // 2. Show loading indicator using the outer screen's context
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (_) => const Center(
                                    child: CircularProgressIndicator(color: Color(0xFF1A237E)),
                                  ),
                                );

                                final selectedItems = selectedIndices.map((idx) => items[idx]).toList();
                                
                                bool success = false;
                                try {
                                  success = await _inventoryService.bulkAddItems(selectedItems);
                                } catch (e) {
                                  debugPrint('Error bulk adding items: $e');
                                } finally {
                                  // Close loading indicator using the screen's navigator pop
                                  if (mounted) {
                                    Navigator.of(context).pop();
                                  }
                                }

                                if (!mounted) return;

                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: Colors.green,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      content: Row(
                                        children: [
                                          const Icon(Icons.check_circle_outline, color: Colors.white),
                                          const SizedBox(width: 8),
                                          Text('Successfully imported/updated ${selectedItems.length} items!'),
                                        ],
                                      ),
                                    ),
                                  );
                                  _fetchData(); // Refresh the list
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: Colors.red,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      content: const Row(
                                        children: [
                                          Icon(Icons.error_outline, color: Colors.white),
                                          SizedBox(width: 8),
                                          Text('Bulk import failed. Please check the backend logs.'),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                              },
                        child: Text(
                          selectedIndices.isEmpty
                              ? 'Confirm & Save'
                              : 'Confirm & Save (${selectedIndices.length})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8EAF6)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    value,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1A237E)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, int count, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showAddItemSheet() {
    final TextEditingController skuController = TextEditingController();
    final TextEditingController nameController = TextEditingController();
    final TextEditingController priceController = TextEditingController();
    final TextEditingController purchasePriceController = TextEditingController();
    final TextEditingController stockController =
        TextEditingController(text: '2');
    final TextEditingController alertController =
        TextEditingController(text: '10');
    String selectedKind = 'FRAME';
    String? selectedVendor = _vendors.isNotEmpty
        ? _vendors.first['name']?.toString()
        : 'Unknown Vendor';
    bool isSavingLocal = false;

    final TextEditingController rSphFrom = TextEditingController();
    final TextEditingController rSphTo = TextEditingController();
    final TextEditingController rCylFrom = TextEditingController();
    final TextEditingController rCylTo = TextEditingController();
    final TextEditingController rAxis = TextEditingController();
    final TextEditingController rAddFrom = TextEditingController();
    final TextEditingController rAddTo = TextEditingController();
    final TextEditingController rQty = TextEditingController(text: '1');

    final TextEditingController lSphFrom = TextEditingController();
    final TextEditingController lSphTo = TextEditingController();
    final TextEditingController lCylFrom = TextEditingController();
    final TextEditingController lCylTo = TextEditingController();
    final TextEditingController lAxis = TextEditingController();
    final TextEditingController lAddFrom = TextEditingController();
    final TextEditingController lAddTo = TextEditingController();
    final TextEditingController lQty = TextEditingController(text: '1');

    final TextEditingController brandNameController = TextEditingController();
    final TextEditingController modelNumberController = TextEditingController();
    final TextEditingController sizeController = TextEditingController();
    final TextEditingController colorController = TextEditingController();
    String selectedFrameType = 'Full';

    bool isREnabled = true;
    bool isLEnabled = true;

    void updateAutoStock() {
      if (selectedKind == 'LENS' || selectedKind == 'CONTACT LENS') {
        final int r = isREnabled ? (int.tryParse(rQty.text) ?? 0) : 0;
        final int l = isLEnabled ? (int.tryParse(lQty.text) ?? 0) : 0;
        stockController.text = (r + l).toString();
      }
    }

    rQty.addListener(updateAutoStock);
    lQty.addListener(updateAutoStock);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
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
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const Text('Add New Product',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A237E))),
                const SizedBox(height: 24),
                _buildModernField(skuController,
                    'Product SKU (e.g. PROD-LENS-900)', Icons.qr_code_outlined),
                const SizedBox(height: 16),
                _buildModernField(
                    nameController, 'Product Name', Icons.inventory_2_outlined),
                const SizedBox(height: 16),
                _buildModernField(
                    brandNameController, 'Brand Name', Icons.branding_watermark_outlined),
                const SizedBox(height: 16),
                const Text('Supplier / Vendor',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54)),
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
                        final String name =
                            (v['name'] ?? v['Name'] ?? 'Unnamed').toString();
                        return DropdownMenuItem(value: name, child: Text(name));
                      }).toList(),
                      onChanged: (val) =>
                          setModalState(() => selectedVendor = val),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Product Kind',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedKind,
                          isExpanded: true,
                          items: [
                            'LENS',
                            'FRAME',
                            'SOLUTIONS',
                            'CONTACT LENS'
                          ]
                              .map((e) => DropdownMenuItem(
                                  value: e, child: Text(e)))
                              .toList(),
                          onChanged: (val) {
                            setModalState(() {
                              selectedKind = val!;
                              updateAutoStock();
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                        child: _buildModernField(purchasePriceController,
                            'Purchase Price (₹)', Icons.shopping_bag_outlined,
                            isNumber: true)),
                    const SizedBox(width: 16),
                    Expanded(
                        child: _buildModernField(priceController,
                            'Sale Price (₹)', Icons.payments_outlined,
                            isNumber: true)),
                  ],
                ),
                if (selectedKind == 'LENS' ||
                    selectedKind == 'CONTACT LENS') ...[
                  const SizedBox(height: 16),
                  _buildLensPowerGrid(
                    setModalState: setModalState,
                    isREnabled: isREnabled,
                    isLEnabled: isLEnabled,
                    onRToggle: (v) {
                      isREnabled = v!;
                      updateAutoStock();
                    },
                    onLToggle: (v) {
                      isLEnabled = v!;
                      updateAutoStock();
                    },
                    rSphFrom: rSphFrom,
                    rSphTo: rSphTo,
                    rCylFrom: rCylFrom,
                    rCylTo: rCylTo,
                    rAxis: rAxis,
                    rAddFrom: rAddFrom,
                    rAddTo: rAddTo,
                    rQty: rQty,
                    lSphFrom: lSphFrom,
                    lSphTo: lSphTo,
                    lCylFrom: lCylFrom,
                    lCylTo: lCylTo,
                    lAxis: lAxis,
                    lAddFrom: lAddFrom,
                    lAddTo: lAddTo,
                    lQty: lQty,
                  ),
                ],
                if (selectedKind == 'FRAME') ...[
                  const SizedBox(height: 16),
                  _buildModernField(modelNumberController,
                      'Model Number', Icons.style_outlined),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildModernField(sizeController,
                            'Size of Frame', Icons.straighten_outlined),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildModernField(colorController,
                            'Color of Frame', Icons.color_lens_outlined),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Frame Type',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedFrameType,
                        isExpanded: true,
                        items: ['Full', 'Half', 'FrameLess']
                            .map((e) => DropdownMenuItem(
                                value: e, child: Text(e, style: const TextStyle(fontSize: 13))))
                            .toList(),
                        onChanged: (val) {
                          setModalState(() {
                            selectedFrameType = val!;
                          });
                        },
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                        child: _buildModernField(stockController,
                            'Opening Stock Qty', Icons.warehouse_outlined,
                            isNumber: true,
                            readOnly: selectedKind == 'LENS' ||
                                selectedKind == 'CONTACT LENS')),
                    const SizedBox(width: 16),
                    Expanded(
                        child: _buildModernField(
                            alertController,
                            'Reorder/Alert Level',
                            Icons.notification_important_outlined,
                            isNumber: true)),
                  ],
                ),
                const SizedBox(height: 32),
                if (isSavingLocal)
                  const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF1A237E)))
                else
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A237E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () async {
                        if (skuController.text.isEmpty ||
                            nameController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('SKU and Name are required!'),
                                  backgroundColor: Colors.red));
                          return;
                        }

                        setModalState(() => isSavingLocal = true);

                        final vendorObj = _vendors.firstWhere(
                            (v) =>
                                (v['name'] ?? v['Name'] ?? '').toString() ==
                                selectedVendor,
                            orElse: () => {});
                        final String? vendorId = vendorObj['id']?.toString() ??
                            vendorObj['id']?.toString();

                        final Map<String, dynamic> finalPayload = {
                          'sku': skuController.text,
                          'name': nameController.text,
                          'kind': (selectedKind == 'SOLUTIONS' ||
                                  selectedKind == 'CONTACT LENS')
                              ? 'ACCESSORY'
                              : selectedKind,
                          'stockQuantity':
                              int.tryParse(stockController.text) ?? 0,
                          'reorderLevel':
                              int.tryParse(alertController.text) ?? 10,
                          'salePrice':
                              double.tryParse(priceController.text) ?? 1200.0,
                          'purchasePrice':
                              double.tryParse(purchasePriceController.text) ?? 0.0,
                          'vendorId': vendorId,
                        };

                        // Conditionally include power info if relevant
                        if (selectedKind == 'LENS' ||
                            selectedKind == 'CONTACT LENS') {
                          final Map<String, dynamic> powerData = {};
                          if (isREnabled) {
                            powerData['rightEye'] = {
                              'sphFrom': rSphFrom.text.trim(),
                              'sphTo': rSphTo.text.trim(),
                              'cylFrom': rCylFrom.text.trim(),
                              'cylTo': rCylTo.text.trim(),
                              'axis': rAxis.text.trim(),
                              'addFrom': rAddFrom.text.trim(),
                              'addTo': rAddTo.text.trim(),
                              'qty': int.tryParse(rQty.text) ?? 1
                            };
                          }
                          if (isLEnabled) {
                            powerData['leftEye'] = {
                              'sphFrom': lSphFrom.text.trim(),
                              'sphTo': lSphTo.text.trim(),
                              'cylFrom': lCylFrom.text.trim(),
                              'cylTo': lCylTo.text.trim(),
                              'axis': lAxis.text.trim(),
                              'addFrom': lAddFrom.text.trim(),
                              'addTo': lAddTo.text.trim(),
                              'qty': int.tryParse(lQty.text) ?? 1
                            };
                          }
                          finalPayload['powerSpecs'] = powerData;
                        }

                        if (selectedKind == 'FRAME') {
                          finalPayload['powerSpecs'] = <String, dynamic>{
                            'brandName': brandNameController.text.trim(),
                            'modelNumber': modelNumberController.text.trim(),
                            'size': sizeController.text.trim(),
                            'color': colorController.text.trim(),
                            'frameType': selectedFrameType,
                          };
                        }

                        final double purchaseVal =
                            double.tryParse(purchasePriceController.text) ?? 0.0;
                        final String brandVal = brandNameController.text.trim();
                        if (finalPayload['powerSpecs'] == null) {
                          finalPayload['powerSpecs'] = <String, dynamic>{
                            'purchasePrice': purchaseVal,
                            'brandName': brandVal,
                          };
                        } else if (finalPayload['powerSpecs'] is Map) {
                          finalPayload['powerSpecs']['purchasePrice'] = purchaseVal;
                          finalPayload['powerSpecs']['brandName'] = brandVal;
                        }

                        final success =
                            await _inventoryService.addItem(finalPayload);

                        if (success && mounted) {
                          Navigator.pop(ctx);
                          _fetchData();
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Product added successfully!'),
                                  backgroundColor: Colors.green));
                        } else {
                          setModalState(() => isSavingLocal = false);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text(
                                  'Failed to add product. SKU may already exist!'),
                              backgroundColor: Colors.red));
                        }
                      },
                      child: const Text('Add to Inventory',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
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

  void _showStockAdjusterSheet(Map<String, dynamic> item) {
    final String productId = (item['id'] ?? '').toString();
    final String currentName =
        (item['name'] ?? item['itemName'] ?? '').toString();
    final String sku = (item['sku'] ?? 'N/A').toString();
    final String currentPrice =
        (item['salePrice'] ?? item['purchasePrice'] ?? 1200.0).toString();
    final String currentStock =
        (item['stockQuantity'] ?? item['openingStockQty'] ?? item['stock'] ?? 0)
            .toString();

    // Find the initial vendor string
    String? currentVendorName;
    if (item['vendorId'] != null) {
      final v = _vendors.firstWhere(
          (ven) => (ven['id']?.toString() == item['vendorId']?.toString()),
          orElse: () => {});
      if (v.isNotEmpty)
        currentVendorName = (v['name'] ?? v['Name'])?.toString();
    }
    if (currentVendorName == null &&
        (item['vendorName'] != null || item['vendor'] != null)) {
      currentVendorName = (item['vendorName'] ?? item['vendor'])?.toString();
    }

    final TextEditingController nameEditController =
        TextEditingController(text: currentName);
    final String currentBrand =
        (item['brandName'] ?? item['powerSpecs']?['brandName'] ?? '').toString();
    final TextEditingController brandNameEditController =
        TextEditingController(text: currentBrand);
    final TextEditingController priceEditController =
        TextEditingController(text: currentPrice);
    final double purchasePriceVal = double.tryParse((item['purchasePrice'] ??
            item['powerSpecs']?['purchasePrice'] ??
            '0.0')
        .toString()) ??
        0.0;
    final TextEditingController purchasePriceEditController =
        TextEditingController(text: purchasePriceVal.toString());
    final TextEditingController qtyController = TextEditingController();
    final TextEditingController reasonCustomController =
        TextEditingController();

    String? selectedVendor = currentVendorName;
    // Ensure selectedVendor matches an entry in _vendors dropdown, or handle gracefully
    if (selectedVendor != null &&
        !_vendors.any((v) =>
            (v['name'] ?? v['Name'] ?? '').toString() == selectedVendor)) {
      selectedVendor = null;
    }

    String selectedReason = 'Manual Adjustment';
    final List<String> reasonOptions = [
      'Manual Adjustment',
      'New Stock Inward',
      'Defective Item Removed (-)',
      'Damaged Goods (-)',
      'Replacement Unit Received (+)',
      'Customer Return (+)',
      'Expired Stock (-)',
      'Other (Write Custom Reason)'
    ];

    bool isSavingLocal = false;
    List<Map<String, dynamic>> history = [];
    List<Map<String, dynamic>> fifoBatches = [];
    bool isLoadingData = true;
    String? selectedBatchId;

    void loadSheetData(StateSetter setModalState) async {
      try {
        final logs = await _inventoryService.getStockHistory(productId);
        final batches = await _inventoryService.getFIFOBatches(productId);
        setModalState(() {
          history = logs;
          fifoBatches = batches;
          isLoadingData = false;
        });
      } catch (_) {
        setModalState(() {
          isLoadingData = false;
        });
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          if (isLoadingData) {
            isLoadingData = false;
            loadSheetData(setModalState);
          }
          return Container(
            height: MediaQuery.of(ctx).size.height * 0.85,
            padding:
                EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2))),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Update Stock / Details',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A237E))),
                      Text('SKU: $sku',
                          style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PRODUCT DETAILS',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Colors.grey[600],
                                letterSpacing: 1)),
                        const SizedBox(height: 16),
                        _buildModernField(
                            nameEditController, 'Product Name', Icons.edit),
                        const SizedBox(height: 16),
                        _buildModernField(
                            brandNameEditController, 'Brand Name', Icons.branding_watermark_outlined),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                                child: _buildModernField(purchasePriceEditController,
                                    'Purchase Price (₹)', Icons.shopping_bag_outlined,
                                    isNumber: true)),
                            const SizedBox(width: 16),
                            Expanded(
                                child: _buildModernField(priceEditController,
                                    'Sale Price (₹)', Icons.payments_outlined,
                                    isNumber: true)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Current Vendor',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black54)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12),
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.grey.shade200),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedVendor,
                                  isExpanded: true,
                                  hint: const Text('Select Vendor',
                                      style: TextStyle(fontSize: 13)),
                                  items: _vendors.map((v) {
                                    final String name = (v['name'] ??
                                            v['Name'] ??
                                            'Unnamed')
                                        .toString();
                                    return DropdownMenuItem(
                                        value: name,
                                        child: Text(name,
                                            style: const TextStyle(
                                                fontSize: 13)));
                                  }).toList(),
                                  onChanged: (val) => setModalState(
                                      () => selectedVendor = val),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: Colors.indigo[50]!.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.indigo[100]!)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('STOCK ADJUSTMENT',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.indigo[700],
                                          letterSpacing: 1)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                        color: Colors.green[100],
                                        borderRadius: BorderRadius.circular(6)),
                                    child: Text('$currentStock In Hand',
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green[900])),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                      flex: 2,
                                      child: _buildModernField(
                                          qtyController,
                                          'Adjustment Qty (+/-)',
                                          Icons.exposure,
                                          isNumber: true)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('Adjustment Reason',
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black54)),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12),
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[50],
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                                color: Colors.grey.shade200),
                                          ),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<String>(
                                              value: selectedReason,
                                              isExpanded: true,
                                              items: reasonOptions
                                                  .map((e) => DropdownMenuItem(
                                                      value: e,
                                                      child: Text(e,
                                                          style:
                                                              const TextStyle(
                                                                  fontSize:
                                                                      12))))
                                                  .toList(),
                                              onChanged: (val) => setModalState(
                                                  () => selectedReason = val!),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              if (selectedReason == 'Manual Adjustment' || selectedReason == 'Other (Write Custom Reason)') ...[
                                const SizedBox(height: 12),
                                _buildModernField(
                                    reasonCustomController,
                                    selectedReason == 'Other (Write Custom Reason)'
                                        ? 'Enter Custom Reason'
                                        : 'Additional Note (Optional)',
                                    Icons.note_alt_outlined),
                              ]
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _showRegisterUnitsDialog(item),
                            icon: const Icon(Icons.qr_code_scanner, size: 16, color: Color(0xFF1A237E)),
                            label: const Text('REGISTER UNIQUE UNIT QRS',
                                style: TextStyle(
                                    color: Color(0xFF1A237E),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11.5,
                                    letterSpacing: 0.5)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF1A237E), width: 1.2),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              backgroundColor: const Color(0xFF1A237E).withOpacity(0.04),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              final int q = int.tryParse(qtyController.text) ?? 1;
                              _orderViaWhatsApp(item, q > 0 ? q : 1);
                            },
                            icon: const Icon(Icons.chat_outlined, color: Colors.green),
                            label: const Text('ORDER FROM VENDOR (WhatsApp)',
                                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.green),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (isSavingLocal)
                          const Center(
                              child: Padding(
                            padding: EdgeInsets.all(12.0),
                            child: CircularProgressIndicator(
                                color: Color(0xFF1A237E)),
                          ))
                        else
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1A237E),
                                foregroundColor: Colors.white,
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () async {
                                setModalState(() => isSavingLocal = true);

                                // 1. Prepare generic metadata updates
                                final double? newPrice =
                                    double.tryParse(priceEditController.text);
                                final String? vId = _vendors
                                    .firstWhere(
                                        (v) =>
                                            (v['name'] ?? v['Name'] ?? '')
                                                .toString() ==
                                            selectedVendor,
                                        orElse: () => {})['id']
                                    ?.toString();

                                final double newPurchasePrice =
                                    double.tryParse(purchasePriceEditController.text) ?? 0.0;

                                final Map<String, dynamic> mergedPowerSpecs =
                                    Map<String, dynamic>.from(item['powerSpecs'] ?? {});
                                mergedPowerSpecs['purchasePrice'] = newPurchasePrice;
                                mergedPowerSpecs['brandName'] = brandNameEditController.text.trim();

                                final Map<String, dynamic> updateData = {
                                  'name': nameEditController.text.trim(),
                                  if (newPrice != null) 'salePrice': newPrice,
                                  'purchasePrice': newPurchasePrice,
                                  'powerSpecs': mergedPowerSpecs,
                                  if (vId != null) 'vendorId': vId,
                                };

                                // 2. Handle Stock Adjustment
                                int adjustment =
                                    int.tryParse(qtyController.text) ?? 0;
                                String finalReason = selectedReason;
                                 if ((selectedReason == 'Manual Adjustment' || selectedReason == 'Other (Write Custom Reason)') &&
                                     reasonCustomController.text.isNotEmpty) {
                                   finalReason =
                                       reasonCustomController.text.trim();
                                 }

                                // Logic guard for Defective Stock: prompt explicit logic?
                                // If it's "Defective Item Removed" and user didn't input negative, we convert it.
                                if ((selectedReason.contains('Defective') ||
                                        selectedReason.contains('Damaged') ||
                                        selectedReason.contains('Expired')) &&
                                    adjustment > 0) {
                                  adjustment =
                                      -adjustment; // Auto-flip to negative
                                }
                                // If it's replacement/inward/return and user entered negative, we flip to positive
                                if ((selectedReason.contains('Replacement') ||
                                        selectedReason.contains('Return') ||
                                        selectedReason.contains('New Stock')) &&
                                    adjustment < 0) {
                                  adjustment = adjustment.abs();
                                }

                                // A. If there are adjustments, combine into payload or call sequential.
                                // Let's perform sequential for now since existing APIs are separate, or if backend supports, single call.
                                if (selectedBatchId != null) {
                                   finalReason = '$finalReason [Batch: $selectedBatchId]';
                                 }

                                 bool op1Success = true;

                                // Call updateProduct first
                                op1Success = await _inventoryService
                                    .updateProduct(productId, updateData);

                                bool op2Success = true;
                                if (adjustment != 0) {
                                  op2Success = await _inventoryService
                                      .updateStock(productId, adjustment,
                                          reason: finalReason);
                                }

                                if (op1Success && op2Success) {
                                  Navigator.pop(ctx);
                                  _fetchData();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Product and Stock updated successfully!'),
                                          backgroundColor: Colors.green));
                                } else {
                                  setModalState(() => isSavingLocal = false);
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                      content: Text(op1Success
                                          ? 'Product updated, but failed to adjust stock'
                                          : 'Failed to update product details.'),
                                      backgroundColor: Colors.red));
                                }
                              },
                              child: const Text('SAVE UPDATES',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15,
                                      letterSpacing: 1)),
                            ),
                          ),
                        if (fifoBatches.isNotEmpty) ...[
                          const SizedBox(height: 32),
                          Row(
                            children: [
                              const Icon(Icons.timer_outlined,
                                  size: 18, color: Color(0xFF1A237E)),
                              const SizedBox(width: 8),
                              const Text('Active Inventory Batches (FIFO)',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1A237E))),
                            ],
                          ),
                          const Text(
                              'Sell oldest stock first. Listed from oldest to newest.',
                              style:
                                  TextStyle(fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 12),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: fifoBatches.length,
                            itemBuilder: (context, i) {
                              final b = fifoBatches[i];
                              final int rem =
                                  (b['remainingQuantity'] ?? 0).toInt();
                              final int orig =
                                  (b['originalQuantity'] ?? 0).toInt();
                              final String dateStr = DateFormat('dd MMM yyyy')
                                  .format(DateTime.parse(b['createdAt']));
                              final bool isOldest = i == 0;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                    color: isOldest
                                        ? Colors.amber[50]
                                        : Colors.green[50]!
                                            .withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: isOldest
                                            ? Colors.amber[200]!
                                            : Colors.green[100]!)),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: isOldest
                                          ? Colors.amber[700]
                                          : Colors.green[600],
                                      child: Text('${i + 1}',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              isOldest
                                                  ? '🎯 SELL THIS FIRST (Oldest)'
                                                  : 'Batch Received ${dateStr}',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                  color: isOldest
                                                      ? Colors.amber[900]
                                                      : Colors.black87)),
                                          Text(
                                              'Received: $dateStr • Type: ${(b['reason'] ?? 'Stock Entry').replaceAll(RegExp(r'\s*\[Batch:\s*[a-zA-Z0-9_-]+\]', caseSensitive: false), '').trim()}',
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey[600])),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text('$rem Left',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w900,
                                                fontSize: 14,
                                                color: Colors.black87)),
                                        Text('of $orig pcs',
                                            style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey)),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          const Text('Target Specific Batch (Optional)',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String?>(
                                value: selectedBatchId,
                                isExpanded: true,
                                hint: const Text('Auto-FIFO (Oldest First)', style: TextStyle(fontSize: 12)),
                                items: [
                                  const DropdownMenuItem<String?>(
                                    value: null,
                                    child: Text('Auto-FIFO (Oldest First)', style: TextStyle(fontSize: 12)),
                                  ),
                                  ...fifoBatches.map((b) {
                                    final String dateStr = DateFormat('dd MMM yyyy')
                                        .format(DateTime.parse(b['createdAt']));
                                    final int rem = (b['remainingQuantity'] ?? 0).toInt();
                                    return DropdownMenuItem<String?>(
                                      value: b['id']?.toString(),
                                      child: Text(
                                        'Batch: $dateStr (${(b['reason'] ?? 'Stock In').replaceAll(RegExp(r'\s*\[Batch:\s*[a-zA-Z0-9_-]+\]', caseSensitive: false), '').trim()}) - $rem Left',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    );
                                  }),
                                ],
                                onChanged: (val) => setModalState(() => selectedBatchId = val),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 32),
                        const Text('Stock Movement History',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A237E))),
                        const SizedBox(height: 12),
                        if (history.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                                child: Text('No historical movements found.',
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 13))),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: history.length,
                            itemBuilder: (context, i) {
                              final log = history[i];
                              final int diff = (log['quantity'] ?? 0).toInt();
                              String reason = log['reason'] ?? 'Stock adjustment';
                              reason = reason.replaceAll(RegExp(r'\s*\[Batch:\s*[a-zA-Z0-9_-]+\]', caseSensitive: false), '').trim();
                              final String dateStr = log['createdAt'] != null
                                  ? DateFormat('dd MMM yyyy, hh:mm a')
                                      .format(DateTime.parse(log['createdAt']))
                                  : 'Recent';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(8)),
                                child: Row(
                                  children: [
                                    Icon(
                                        diff > 0
                                            ? Icons.add_circle
                                            : Icons.remove_circle,
                                        color: diff > 0
                                            ? Colors.green
                                            : Colors.red,
                                        size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(reason,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12)),
                                          Text(dateStr,
                                              style: const TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey)),
                                        ],
                                      ),
                                    ),
                                    Text('${diff > 0 ? "+" : ""}$diff Pcs',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: diff > 0
                                                ? Colors.green
                                                : Colors.red,
                                            fontSize: 14)),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildModernField(
      TextEditingController controller, String label, IconData icon,
      {bool isNumber = false, bool readOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black54)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: isNumber
              ? const TextInputType.numberWithOptions(signed: true)
              : TextInputType.text,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: const Color(0xFF1A237E)),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFF1A237E), width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildLensPowerGrid({
    required StateSetter setModalState,
    required bool isREnabled,
    required bool isLEnabled,
    required Function(bool?) onRToggle,
    required Function(bool?) onLToggle,
    required TextEditingController rSphFrom,
    required TextEditingController rSphTo,
    required TextEditingController rCylFrom,
    required TextEditingController rCylTo,
    required TextEditingController rAxis,
    required TextEditingController rAddFrom,
    required TextEditingController rAddTo,
    required TextEditingController rQty,
    required TextEditingController lSphFrom,
    required TextEditingController lSphTo,
    required TextEditingController lCylFrom,
    required TextEditingController lCylTo,
    required TextEditingController lAxis,
    required TextEditingController lAddFrom,
    required TextEditingController lAddTo,
    required TextEditingController lQty,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Expanded(
                  flex: 3,
                  child: Text('EYE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          color: Colors.black54,
                          letterSpacing: 0.5))),
              Expanded(
                  flex: 3,
                  child: Text('SPH RANGE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          color: Colors.black54))),
              Expanded(
                  flex: 3,
                  child: Text('CYL RANGE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          color: Colors.black54))),
              Expanded(
                  flex: 3,
                  child: Text('AXIS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          color: Colors.black54))),
              Expanded(
                  flex: 3,
                  child: Text('ADD RANGE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          color: Colors.black54))),
              Expanded(
                  flex: 2,
                  child: Text('QTY',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          color: Colors.black54))),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _buildRow(setModalState, 'R', isREnabled, (v) {
          setModalState(() => onRToggle(v));
        }, rSphFrom, rSphTo, rCylFrom, rCylTo, rAxis, rAddFrom, rAddTo, rQty),
        const SizedBox(height: 8),
        _buildRow(setModalState, 'L', isLEnabled, (v) {
          setModalState(() => onLToggle(v));
        }, lSphFrom, lSphTo, lCylFrom, lCylTo, lAxis, lAddFrom, lAddTo, lQty),
      ],
    );
  }

  Widget _buildRow(
      StateSetter setModalState,
      String label,
      bool enabled,
      Function(bool?) toggle,
      TextEditingController sphFrom,
      TextEditingController sphTo,
      TextEditingController cylFrom,
      TextEditingController cylTo,
      TextEditingController axis,
      TextEditingController addFrom,
      TextEditingController addTo,
      TextEditingController qty) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5FB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Checkbox(
                  value: enabled,
                  onChanged: toggle,
                  activeColor: const Color(0xFF1A237E),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                ),
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 13)),
              ],
            ),
          ),
          Expanded(
              flex: 3,
              child: _buildMiniRangeInput(sphFrom, sphTo, enabled)),
          const SizedBox(width: 4),
          Expanded(
              flex: 3,
              child: _buildMiniRangeInput(cylFrom, cylTo, enabled)),
          const SizedBox(width: 4),
          Expanded(flex: 3, child: _buildMiniInput(axis, enabled, height: 78)),
          const SizedBox(width: 4),
          Expanded(
              flex: 3,
              child: _buildMiniRangeInput(addFrom, addTo, enabled)),
          const SizedBox(width: 8),
          Expanded(flex: 2, child: _buildMiniInput(qty, enabled, height: 78)),
        ],
      ),
    );
  }

  Widget _buildMiniRangeInput(
      TextEditingController from, TextEditingController to, bool enabled) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildMiniInput(from, enabled, hint: 'FROM'),
        const SizedBox(height: 6),
        _buildMiniInput(to, enabled, hint: 'TO'),
      ],
    );
  }

  Widget _buildMiniInput(TextEditingController ctrl, bool enabled,
      {String? hint, double height = 36}) {
    return SizedBox(
      height: height,
      child: TextField(
        controller: ctrl,
        enabled: enabled,
        textAlign: TextAlign.center,
        keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
        style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: enabled ? const Color(0xFF1A237E) : Colors.grey[600]),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 9, color: Colors.grey[400], letterSpacing: 0.5),
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey[100],
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF1A237E), width: 1.5),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
        ),
      ),
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
          title: const Text('Store Inventory',
              style: TextStyle(fontWeight: FontWeight.bold)),
          bottom: TabBar(
            labelStyle:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
              icon: const Icon(Icons.qr_code_scanner, size: 28),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QRScannerHubScreen(initialMode: 'inventory')),
                );
                _fetchData(); // Auto refresh when coming back
              },
            ),
            IconButton(
              icon: const Icon(Icons.file_upload_outlined, size: 28),
              tooltip: 'Import Excel / PDF',
              onPressed: _importFile,
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 28),
              onPressed: _showAddItemSheet,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF1A237E)))
            : TabBarView(
                children: [
                  Column(
                    children: [
                      _buildSearchAndFilters(),
                      if (_startDate != null) _buildActiveDateFilter(),
                      if (_isPowerFiltered()) _buildActivePowerFilter(),
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
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _barcodeController,
            onChanged: (val) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search by SKU or name...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF1A237E)),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    children: [
                      'All',
                      'Frames',
                      'Lenses',
                      'Contact Lenses',
                      'Solutions',
                      'Accessories'
                    ].map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(cat,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal)),
                          selected: isSelected,
                          onSelected: (val) =>
                              setState(() => _selectedCategory = cat),
                          backgroundColor: Colors.grey[100],
                          selectedColor: const Color(0xFF1A237E),
                          checkmarkColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide.none),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildCircleButton(
                  icon: Icons.tune,
                  isSelected: _isPowerFiltered(),
                  onTap: _showPowerFilterSheet),
              const SizedBox(width: 8),
              _buildCircleButton(
                  icon: Icons.calendar_month_outlined,
                  isSelected: _startDate != null,
                  onTap: _selectDateRange),
              const SizedBox(width: 8),
              _buildCircleButton(
                  icon:
                      _isAscending ? Icons.arrow_downward : Icons.arrow_upward,
                  onTap: () => setState(() => _isAscending = !_isAscending)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton(
      {required IconData icon,
      bool isSelected = false,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A237E) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon,
            size: 20,
            color: isSelected ? Colors.white : const Color(0xFF1A237E)),
      ),
    );
  }

  Widget _buildActiveDateFilter() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: Colors.blue[50], borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.date_range, size: 16, color: Color(0xFF1A237E)),
          const SizedBox(width: 8),
          Text(
            'Showing: ${DateFormat('dd MMM').format(_startDate!)} - ${DateFormat('dd MMM').format(_endDate!)}',
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A237E)),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() {
              _startDate = null;
              _endDate = null;
            }),
            child: const Icon(Icons.close, size: 16, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryList() {
    final filtered = _getFilteredItems(_inventory);
    if (filtered.isEmpty) {
      return const Center(
          child: Text('No products found matching your filter.',
              style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final item = filtered[index];
        final String powerText = _formatPowerSpecs(item['powerSpecs']);
        final int stock = (item['stockQuantity'] ??
                item['openingStockQty'] ??
                item['stock'] ??
                0)
            .toInt();
        final int alertLevel =
            (item['reorderLevel'] ?? item['alertQty'] ?? 10).toInt();
        final bool isLow = stock < alertLevel;
        final String kind = (item['kind'] ?? item['groupName'] ?? 'LENS')
            .toString()
            .toUpperCase();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ],
          ),
          child: InkWell(
            onTap: () => _showStockAdjusterSheet(item),
            borderRadius: BorderRadius.circular(16),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isLow ? Colors.red : const Color(0xFF1A237E))
                      .withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                    kind == 'FRAME'
                        ? Icons.visibility_outlined
                        : Icons.inventory_2_outlined,
                    color: isLow ? Colors.red : const Color(0xFF1A237E),
                    size: 22),
              ),
              title: Text(
                  (item['name'] ?? item['itemName'] ?? 'Unknown Product')
                      .toString(),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Builder(
                    builder: (context) {
                      final double salePrice = double.tryParse((item['salePrice'] ?? '0.0').toString()) ?? 0.0;
                      final double purchasePrice = double.tryParse((item['purchasePrice'] ?? item['powerSpecs']?['purchasePrice'] ?? '0.0').toString()) ?? 0.0;
                      return Text(
                          '${item['sku'] ?? 'N/A'} • ${item['kind'] ?? item['groupName'] ?? 'LENS'}'
                          ' • Purchase: ₹${purchasePrice.toStringAsFixed(0)} • Sale: ₹${salePrice.toStringAsFixed(0)}',
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]));
                    }
                  ),
                  if (powerText.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A237E).withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        powerText,
                        style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A237E)),
                      ),
                    ),
                  ],
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$stock Pcs',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: isLow ? Colors.red : Colors.green[700])),
                  Text(isLow ? 'LOW STOCK' : 'IN STOCK',
                      style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: isLow ? Colors.red : Colors.grey)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlertsTab() {
    final alerts = _inventory.where((item) {
      final int stock = (item['stockQuantity'] ??
              item['openingStockQty'] ??
              item['stock'] ??
              0)
          .toInt();
      final int alertLevel =
          (item['reorderLevel'] ?? item['alertQty'] ?? 10).toInt();
      return stock < alertLevel;
    }).toList();

    if (alerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline,
                size: 60, color: Colors.green[200]),
            const SizedBox(height: 16),
            const Text('All stock levels are healthy!',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: alerts.length,
      itemBuilder: (context, index) {
        final item = alerts[index];
        final String powerText = _formatPowerSpecs(item['powerSpecs']);
        final String vendor =
            item['vendorName'] ?? item['vendor'] ?? 'No Vendor';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red[100]!),
          ),
          child: ListTile(
            leading: const Icon(Icons.warning_amber_rounded,
                color: Colors.red, size: 28),
            title: Text(
                (item['name'] ?? item['itemName'] ?? 'Unknown Product')
                    .toString(),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.red)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'Stock: ${item['stockQuantity'] ?? item['openingStockQty'] ?? item['stock'] ?? 0} | Reorder: ${item['reorderLevel'] ?? item['alertQty'] ?? 10}',
                    style: TextStyle(color: Colors.red[700], fontSize: 11)),
                if (powerText.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red[100]!.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      powerText,
                      style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.red),
                    ),
                  ),
                ],
              ],
            ),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          VendorMasterScreen(initialVendorName: vendor)),
                );
              },
              child: const Text('RESTOCK',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
        );
      },
    );
  }

  void _showRegisterUnitsDialog(Map<String, dynamic> item) async {
    final String productId = item['id'] ?? '';
    final String productName = item['name'] ?? '';
    final String sku = item['sku'] ?? 'vik';
    final int currentStock = (item['stockQuantity'] ?? 0).toInt();

    int maxSerial = 0;
    try {
      maxSerial = await _inventoryService.getMaxSerial(productId);
    } catch (_) {}

    final int nextStart = maxSerial + 1;

    final TextEditingController _codesController = TextEditingController();
    final TextEditingController _prefixController = TextEditingController(
        text: '${sku.toLowerCase().replaceAll(' ', '-')}-');
    final TextEditingController _qtyController =
        TextEditingController(text: '$currentStock');
    final TextEditingController _startController =
        TextEditingController(text: '$nextStart');
    bool _isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (context, setState) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          backgroundColor: Colors.white,
          child: Container(
            width: 520,
            constraints: const BoxConstraints(maxWidth: 550),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Premium Dialog Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A237E).withOpacity(0.04),
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Register Unique Units & QRs',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Color(0xFF1A237E),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                productName,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          style: IconButton.styleFrom(
                            hoverColor: Colors.grey.shade100,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Specs Alert Banner
                        if (_formatPowerSpecs(item['powerSpecs']).isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.blue.shade100),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, size: 16, color: Colors.blue.shade800),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _formatPowerSpecs(item['powerSpecs']).startsWith('Brand:')
                                        ? _formatPowerSpecs(item['powerSpecs'])
                                        : 'Power Specs: ${_formatPowerSpecs(item['powerSpecs'])}',
                                    style: TextStyle(
                                      color: Colors.blue.shade900,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // BULK AUTO-GENERATOR CARD
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.auto_awesome, size: 16, color: Color(0xFF1A237E)),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Bulk QR Auto-Generator',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Color(0xFF1A237E),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: TextField(
                                      controller: _prefixController,
                                      decoration: InputDecoration(
                                        labelText: 'Prefix',
                                        labelStyle: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(color: Color(0xFF1A237E), width: 1.5),
                                        ),
                                      ),
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 2,
                                    child: TextField(
                                      controller: _qtyController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: 'Qty',
                                        labelStyle: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(color: Color(0xFF1A237E), width: 1.5),
                                        ),
                                      ),
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 2,
                                    child: TextField(
                                      controller: _startController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: 'Start #',
                                        labelStyle: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(color: Color(0xFF1A237E), width: 1.5),
                                        ),
                                      ),
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                height: 34,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1A237E),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                  ),
                                  icon: const Icon(Icons.flash_on, size: 14),
                                  label: const Text('GENERATE & PRE-FILL',
                                      style: TextStyle(
                                          fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                  onPressed: () {
                                    final String prefix = _prefixController.text.trim();
                                    final int count = int.tryParse(_qtyController.text) ?? 0;
                                    final int start = int.tryParse(_startController.text) ?? 1;
                                    if (count <= 0) return;

                                    final List<String> generated = [];
                                    for (int i = 0; i < count; i++) {
                                      final int num = start + i;
                                      final String paddedNum = num.toString().padLeft(3, '0');
                                      generated.add('$prefix$paddedNum');
                                    }

                                    setState(() {
                                      _codesController.text = generated.join(', ');
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Unique Serialized Codes to Register:',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                            ),
                            if (_codesController.text.isNotEmpty)
                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _codesController.clear();
                                  });
                                },
                                icon: const Icon(Icons.delete_outline, size: 14, color: Colors.red),
                                label: const Text('Clear', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _codesController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Codes will appear here. Or scan/paste them.',
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade200),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF1A237E), width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade800, fontFamily: 'monospace'),
                          onChanged: (val) {
                            setState(() {}); // trigger refresh for Clear button visibility
                          },
                        ),
                        if (_isSubmitting)
                          const Padding(
                              padding: EdgeInsets.only(top: 16),
                              child: Center(child: CircularProgressIndicator())),
                      ],
                    ),
                  ),

                  // Premium Dialog Footer
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade200, width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey.shade600,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          child: const Text('CANCEL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade600,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          icon: const Icon(Icons.print, size: 14),
                          label: const Text('PRINT & REGISTER LABELS',
                              style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                          onPressed: _isSubmitting
                              ? null
                              : () async {
                                  final String raw = _codesController.text.trim();
                                  if (raw.isEmpty) return;

                                  final List<String> codes = raw
                                      .split(RegExp(r'[,\s]+'))
                                      .map((c) => c.trim())
                                      .where((c) => c.isNotEmpty)
                                      .toList();

                                  if (codes.isEmpty) return;

                                  // 1. AUTO-SAVE TO DATABASE FIRST SO THEY NEVER FORGET!
                                  setState(() => _isSubmitting = true);
                                  final bool ok = await _inventoryService.registerUnits(
                                      productId, codes);
                                  setState(() => _isSubmitting = false);

                                  if (!ok) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                        content: Text(
                                            'Auto-registration failed. One of these codes may already exist in your system.'),
                                        backgroundColor: Colors.red));
                                    return; // STOP! Don't print unregistered labels
                                  }

                                  // 2. GENERATE AND PRINT PDF WITH EXACT 70mm x 35mm LABELS
                                  try {
                                    final doc = pw.Document();
                                    final double labelWidth = 70 * PdfPageFormat.mm;
                                    final double labelHeight = 35 * PdfPageFormat.mm;
                                    final customFormat = PdfPageFormat(
                                      labelWidth,
                                      labelHeight,
                                      marginAll: 1.5 * PdfPageFormat.mm,
                                    );

                                    final String powerStr = _formatPowerSpecs(item['powerSpecs'], multiLine: true);

                                    for (final code in codes) {
                                      doc.addPage(
                                        pw.Page(
                                          pageFormat: customFormat,
                                          build: (context) {
                                            return pw.Row(
                                              crossAxisAlignment: pw.CrossAxisAlignment.center,
                                              children: [
                                                // Left Side: QR Code + readable code text
                                                pw.Column(
                                                  mainAxisAlignment: pw.MainAxisAlignment.center,
                                                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                                                  children: [
                                                    pw.BarcodeWidget(
                                                      barcode: pw.Barcode.qrCode(),
                                                      data: code,
                                                      width: 44,
                                                      height: 44,
                                                    ),
                                                    pw.SizedBox(height: 1),
                                                    pw.Text(
                                                      code,
                                                      style: pw.TextStyle(
                                                          fontSize: 6,
                                                          fontWeight: pw.FontWeight.bold),
                                                    ),
                                                  ],
                                                ),
                                                pw.SizedBox(width: 6),
                                                // Right Side: Item Details (Name, SKU, Power/Specs)
                                                pw.Expanded(
                                                  child: pw.Column(
                                                    mainAxisAlignment: pw.MainAxisAlignment.center,
                                                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                                                    children: [
                                                      pw.Text(
                                                        productName,
                                                        style: pw.TextStyle(
                                                            fontSize: 7.5,
                                                            fontWeight: pw.FontWeight.bold),
                                                        maxLines: 2,
                                                        overflow: pw.TextOverflow.clip,
                                                      ),
                                                      pw.SizedBox(height: 1.5),
                                                      pw.Text(
                                                        'SKU: $sku',
                                                        style: const pw.TextStyle(
                                                            fontSize: 6.5,
                                                            color: PdfColors.grey700),
                                                      ),
                                                      if (powerStr.isNotEmpty) ...[
                                                        pw.SizedBox(height: 1.5),
                                                        ...powerStr.split('\n').map((line) => pw.FittedBox(
                                                          fit: pw.BoxFit.scaleDown,
                                                          alignment: pw.Alignment.centerLeft,
                                                          child: pw.Text(
                                                            line,
                                                            style: const pw.TextStyle(
                                                                fontSize: 5.5,
                                                                color: PdfColors.grey600),
                                                          ),
                                                        )),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      );
                                    }

                                    await Printing.layoutPdf(
                                      onLayout: (PdfPageFormat format) async => doc.save(),
                                    );

                                    // Automatically pop dialog on success and show beautiful snackbar
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                        content: Text(
                                            'Successfully registered and printed ${codes.length} unique labels!'),
                                        backgroundColor: Colors.green));
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                        content: Text('Error printing labels: $e'),
                                        backgroundColor: Colors.red));
                                  }
                                },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  String _formatRange(dynamic from, dynamic to, {bool compact = false}) {
    final String fStr = (from ?? '').toString().trim();
    final String tStr = (to ?? '').toString().trim();
    if (fStr.isEmpty && tStr.isEmpty) return '';
    if (fStr.isEmpty) return tStr;
    if (tStr.isEmpty) return fStr;
    if (fStr == tStr) return fStr;
    return compact ? '$fStr-$tStr' : '$fStr to $tStr';
  }

  String _formatPowerSpecs(dynamic rawSpecs, {bool multiLine = false}) {
    if (rawSpecs == null) return '';
    try {
      final Map<String, dynamic> specs = rawSpecs is Map
          ? Map<String, dynamic>.from(rawSpecs)
          : {};
      if (specs.isEmpty) return '';

      final bool hasRightEye = specs.containsKey('rightEye') && specs['rightEye'] != null;
      final bool hasLeftEye = specs.containsKey('leftEye') && specs['leftEye'] != null;

      if (!hasRightEye && !hasLeftEye) {
        if (specs.containsKey('brandName') ||
            specs.containsKey('modelNumber') ||
            specs.containsKey('frameType')) {
          final List<String> frameParts = [];
          final String brand = (specs['brandName'] ?? '').toString().trim();
          final String model = (specs['modelNumber'] ?? '').toString().trim();
          final String type = (specs['frameType'] ?? '').toString().trim();
          final String size = (specs['size'] ?? '').toString().trim();
          final String color = (specs['color'] ?? '').toString().trim();

          if (brand.isNotEmpty) frameParts.add('Brand: $brand');
          if (model.isNotEmpty) frameParts.add('Model: $model');
          if (type.isNotEmpty) frameParts.add('Type: $type');
          if (size.isNotEmpty) frameParts.add('Size: $size');
          if (color.isNotEmpty) frameParts.add('Color: $color');

          return frameParts.join(' | ');
        }
      }

      final List<String> parts = [];

      void processEye(String key, String label) {
        final eye = specs[key];
        if (eye != null && eye is Map) {
          final String sph = _formatRange(eye['sphFrom'], eye['sphTo'], compact: multiLine);
          final String cyl = _formatRange(eye['cylFrom'], eye['cylTo'], compact: multiLine);
          final String axis = (eye['axis'] ?? '').toString().trim();
          final String addVal = _formatRange(eye['addFrom'], eye['addTo'], compact: multiLine);

          final List<String> eyeBits = [];
          if (sph.isNotEmpty) eyeBits.add('SPH $sph');
          if (cyl.isNotEmpty) eyeBits.add('CYL $cyl');
          if (axis.isNotEmpty) eyeBits.add(multiLine ? 'AX $axis' : 'AXIS $axis');
          if (addVal.isNotEmpty) eyeBits.add('ADD $addVal');

          if (eyeBits.isNotEmpty) {
            parts.add('$label: ${eyeBits.join(", ")}');
          }
        }
      }

      processEye('rightEye', 'R');
      processEye('leftEye', 'L');

      return parts.join(multiLine ? '\n' : ' | ');
    } catch (_) {
      return '';
    }
  }

  void _showPowerFilterSheet() {
    String tempMode = _fSearchMode;
    bool tempRE = _fREnabled;
    final TextEditingController rSf = TextEditingController(text: _fRSphFrom);
    final TextEditingController rSt = TextEditingController(text: _fRSphTo);
    final TextEditingController rCf = TextEditingController(text: _fRCylFrom);
    final TextEditingController rCt = TextEditingController(text: _fRCylTo);
    final TextEditingController rAx = TextEditingController(text: _fRAxis);

    bool tempLE = _fLEnabled;
    final TextEditingController lSf = TextEditingController(text: _fLSphFrom);
    final TextEditingController lSt = TextEditingController(text: _fLSphTo);
    final TextEditingController lCf = TextEditingController(text: _fLCylFrom);
    final TextEditingController lCt = TextEditingController(text: _fLCylTo);
    final TextEditingController lAx = TextEditingController(text: _fLAxis);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (context, setModalState) {
        Widget buildFilterGridRow(
            String label,
            bool enabled,
            Function(bool?) onToggle,
            TextEditingController sF,
            TextEditingController sT,
            TextEditingController cF,
            TextEditingController cT,
            TextEditingController ax) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: enabled ? Colors.white : Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: enabled ? const Color(0xFF1A237E).withOpacity(0.3) : Colors.grey[200]!,
                width: enabled ? 1.5 : 1.0,
              ),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                          color: Colors.blue.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4))
                    ]
                  : [],
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                      flex: 14,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Checkbox(
                            value: enabled,
                            onChanged: onToggle,
                            activeColor: const Color(0xFF1A237E),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          ),
                          const SizedBox(height: 4),
                          Text(label,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                  color: Color(0xFF1A237E))),
                        ],
                      )),
                  VerticalDivider(width: 12, thickness: 1, color: Colors.grey[200]!),
                  Expanded(flex: 33, child: _buildMiniRangeInput(sF, sT, enabled)),
                  VerticalDivider(width: 12, thickness: 1, color: Colors.grey[200]!),
                  Expanded(flex: 33, child: _buildMiniRangeInput(cF, cT, enabled)),
                  VerticalDivider(width: 12, thickness: 1, color: Colors.grey[200]!),
                  Expanded(flex: 20, child: _buildMiniInput(ax, enabled, hint: 'AXIS', height: 78)),
                ],
              ),
            ),
          );
        }

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              left: 16,
              right: 16,
              top: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Filter by Power Range',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A237E))),
                  CircleAvatar(
                    backgroundColor: Colors.grey[100],
                    radius: 18,
                    child: IconButton(
                        icon: const Icon(Icons.close, size: 18, color: Colors.black87),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => Navigator.pop(context)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('POWER STRATEGY:',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: Colors.grey)),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            'Single R',
                            'Single L',
                            'Both (Same)',
                            'Both (Diff)'
                          ].map((m) {
                            final isSel = tempMode == m;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(m,
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                        color: isSel ? Colors.white : Colors.black87)),
                                selected: isSel,
                                selectedColor: const Color(0xFF1A237E),
                                checkmarkColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                onSelected: (v) => setModalState(() {
                                  tempMode = v ? m : 'Any';
                                  if (tempMode == 'Single R') {
                                    tempRE = true; tempLE = false;
                                  } else if (tempMode == 'Single L') {
                                    tempRE = false; tempLE = true;
                                  } else {
                                    tempRE = true; tempLE = true;
                                  }
                                }),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: Row(
                          children: [
                            Expanded(flex: 14, child: Text('EYE', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey[700], letterSpacing: 0.5))),
                            const SizedBox(width: 12),
                            Expanded(flex: 33, child: Text('SPH RANGE', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey[700], letterSpacing: 0.5))),
                            const SizedBox(width: 12),
                            Expanded(flex: 33, child: Text('CYL RANGE', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey[700], letterSpacing: 0.5))),
                            const SizedBox(width: 12),
                            Expanded(flex: 20, child: Text('AXIS', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey[700], letterSpacing: 0.5))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      if (tempMode == 'Any' || tempMode == 'Single R' || tempMode.startsWith('Both'))
                        buildFilterGridRow(
                            tempMode == 'Both (Same)' ? 'RL' : 'R',
                            tempRE, 
                            (v) => setModalState(() => tempRE = v!),
                            rSf, rSt, rCf, rCt, rAx),
                      
                      // Hide L row if 'Both (Same)' is selected since user only needs to fill 1 row!
                      if (tempMode == 'Any' || tempMode == 'Single L' || tempMode == 'Both (Diff)')
                        buildFilterGridRow('L', tempLE, (v) => setModalState(() => tempLE = v!),
                            lSf, lSt, lCf, lCt, lAx),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              
              Container(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey[200]!)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _fSearchMode = 'Any';
                            _fREnabled = false;
                            _fLEnabled = false;
                            _fRSphFrom = ''; _fRSphTo = ''; _fRCylFrom = ''; _fRCylTo = ''; _fRAxis = '';
                            _fLSphFrom = ''; _fLSphTo = ''; _fLCylFrom = ''; _fLCylTo = ''; _fLAxis = '';
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('CLEAR ALL', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A237E),
                            foregroundColor: Colors.white,
                            elevation: 2,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        onPressed: () {
                          final bool isBothSame = tempMode == 'Both (Same)';
                          setState(() {
                            _fSearchMode = tempMode;
                            _fREnabled = tempRE;
                            _fRSphFrom = rSf.text;
                            _fRSphTo = rSt.text;
                            _fRCylFrom = rCf.text;
                            _fRCylTo = rCt.text;
                            _fRAxis = rAx.text;
        
                            // Auto-mirror Right data to Left if Both Same is selected
                            _fLEnabled = isBothSame ? tempRE : tempLE;
                            _fLSphFrom = isBothSame ? rSf.text : lSf.text;
                            _fLSphTo = isBothSame ? rSt.text : lSt.text;
                            _fLCylFrom = isBothSame ? rCf.text : lCf.text;
                            _fLCylTo = isBothSame ? rCt.text : lCt.text;
                            _fLAxis = isBothSame ? rAx.text : lAx.text;
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('APPLY FILTERS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildActivePowerFilter() {
    final List<String> summary = [];
    if (_fSearchMode != 'Any') summary.add(_fSearchMode);
    if (_fREnabled) summary.add('Right Eye Criteria');
    if (_fLEnabled) summary.add('Left Eye Criteria');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: Colors.indigo[50], borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.tune, size: 16, color: Color(0xFF1A237E)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Active: ${summary.join(" | ")}',
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E)),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() {
              _fSearchMode = 'Any';
              _fREnabled = false;
              _fLEnabled = false;
            }),
            child: const Icon(Icons.close, size: 16, color: Colors.red),
          ),
        ],
      ),
    );
  }

  bool _doesRangeOverlap(
      String? qFromStr, String? qToStr, dynamic dbFrom, dynamic dbTo) {
    final double? qF = (qFromStr != null && qFromStr.isNotEmpty)
        ? double.tryParse(qFromStr)
        : null;
    final double? qT = (qToStr != null && qToStr.isNotEmpty)
        ? double.tryParse(qToStr)
        : null;

    if (qF == null && qT == null) return true;

    final double? dF = double.tryParse((dbFrom ?? '').toString());
    final double? dT = double.tryParse((dbTo ?? '').toString());

    if (dF == null && dT == null) return false;

    final double dbMin =
        (dF != null && dT != null) ? math.min(dF, dT) : (dF ?? dT)!;
    final double dbMax =
        (dF != null && dT != null) ? math.max(dF, dT) : (dF ?? dT)!;

    if (qF != null && qT == null) return qF >= dbMin && qF <= dbMax;
    if (qF == null && qT != null) return qT >= dbMin && qT <= dbMax;

    final double qMin = math.min(qF!, qT!);
    final double qMax = math.max(qF!, qT!);

    // Ensure database range is fully contained within user requested window
    return (dbMin >= qMin) && (dbMax <= qMax);
  }
}
