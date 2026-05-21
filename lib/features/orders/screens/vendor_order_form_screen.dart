import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/master_data_service.dart';

class VendorOrderFormScreen extends StatefulWidget {
  final Map<String, dynamic> vendor;
  final List<Map<String, dynamic>> initialItems;

  const VendorOrderFormScreen({
    super.key,
    required this.vendor,
    this.initialItems = const [],
  });

  @override
  State<VendorOrderFormScreen> createState() => _VendorOrderFormScreenState();
}

class _VendorOrderFormScreenState extends State<VendorOrderFormScreen> {
  final MasterDataService _masterDataService = MasterDataService();
  final List<VendorOrderItem> _orderItems = [];
  final TextEditingController _globalNotesController = TextEditingController();
  List<Map<String, dynamic>> _allBackendItems = [];
  bool _isLoadingItems = true;

  @override
  void initState() {
    super.initState();
    _loadBackendItems();
    _addOrderItem();
  }

  Future<void> _loadBackendItems() async {
    setState(() => _isLoadingItems = true);
    try {
      final items = await _masterDataService.fetchItems();
      setState(() {
        _allBackendItems = items;
        _isLoadingItems = false;
      });
    } catch (e) {
      debugPrint('Error loading backend items: $e');
      setState(() {
        _allBackendItems = widget.initialItems;
        _isLoadingItems = false;
      });
    }
  }

  void _addOrderItem() {
    setState(() {
      _orderItems.add(VendorOrderItem());
    });
  }

  void _removeOrderItem(int index) {
    setState(() {
      _orderItems[index].dispose();
      _orderItems.removeAt(index);
    });
  }

  String _formatRange(String from, String to) {
    if (from.isEmpty) return to;
    if (to.isEmpty) return from;
    if (from == to) return from;
    return "$from to $to";
  }

  void _sendToWhatsApp() async {
    final String vendorName = widget.vendor['name'] ?? widget.vendor['Name'] ?? 'Vendor';
    final String vendorPhone = widget.vendor['phone'] ?? widget.vendor['MobileNumber'] ?? '';

    if (vendorPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vendor phone number missing!'), backgroundColor: Colors.orange)
      );
      return;
    }

    if (_orderItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item to the order'), backgroundColor: Colors.orange)
      );
      return;
    }

    String message = "Hello $vendorName,\n\nI would like to place an order for the following items:\n\n";

    for (int i = 0; i < _orderItems.length; i++) {
      final item = _orderItems[i];
      final String name = item.itemNameController.text.trim();
      if (name.isEmpty) continue;

      message += "${i + 1}. *Category:* ${item.category}\n";
      message += "   *Item:* $name\n";

      void addEyeDetails(String label, bool isSelected, TextEditingController sphF, TextEditingController sphT, TextEditingController cylF, TextEditingController cylT, TextEditingController ax, TextEditingController addF, TextEditingController addT, TextEditingController q) {
        if (!isSelected) return;
        final String sph = _formatRange(sphF.text.trim(), sphT.text.trim());
        final String cyl = _formatRange(cylF.text.trim(), cylT.text.trim());
        final String axis = ax.text.trim();
        final String add = _formatRange(addF.text.trim(), addT.text.trim());
        final String qty = q.text.trim();

        message += "   *[$label Eye]* ";
        List<String> bits = [];
        if (sph.isNotEmpty) bits.add("SPH: $sph");
        if (cyl.isNotEmpty) bits.add("CYL: $cyl");
        if (axis.isNotEmpty) bits.add("AXIS: $axis");
        if (add.isNotEmpty) bits.add("ADD: $add");
        bits.add("QTY: $qty");
        message += bits.join(", ") + "\n";
      }

      if (item.powerStrategy == 'Both (Same)') {
        addEyeDetails('BOTH', item.isRightSelected, item.rSphFrom, item.rSphTo, item.rCylFrom, item.rCylTo, item.rAxis, item.rAddFrom, item.rAddTo, item.rQty);
      } else {
        addEyeDetails('R', item.isRightSelected, item.rSphFrom, item.rSphTo, item.rCylFrom, item.rCylTo, item.rAxis, item.rAddFrom, item.rAddTo, item.rQty);
        addEyeDetails('L', item.isLeftSelected, item.lSphFrom, item.lSphTo, item.lCylFrom, item.lCylTo, item.lAxis, item.lAddFrom, item.lAddTo, item.lQty);
      }
      message += "\n";
    }

    if (_globalNotesController.text.isNotEmpty) {
      message += "Notes: ${_globalNotesController.text.trim()}\n\n";
    }

    message += "Please confirm availability and estimated delivery.\nThank you!";

    String cleanPhone = vendorPhone.replaceAll(RegExp(r'\D'), '');
    if (!cleanPhone.startsWith('91') && cleanPhone.length == 10) {
      cleanPhone = '91$cleanPhone';
    }

    final url = "https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}";
    
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  void _confirmReset() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 12),
            Text('Reset Form?', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text('This will clear all items and notes you have entered. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _resetForm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    setState(() {
      for (var item in _orderItems) {
        item.dispose();
      }
      _orderItems.clear();
      _globalNotesController.clear();
      _addOrderItem();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Form cleared successfully'), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String vendorName = widget.vendor['name'] ?? widget.vendor['Name'] ?? 'Vendor';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('WhatsApp Order Form', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('To: $vendorName', style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        elevation: 0,
        backgroundColor: const Color(0xFF1A237E),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Form',
            onPressed: _confirmReset,
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _orderItems.length + 1,
        itemBuilder: (context, index) {
          if (index == _orderItems.length) {
            return Column(
              children: [
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _addOrderItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Another Item'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[50],
                    foregroundColor: const Color(0xFF1A237E),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.blue.shade100)),
                  ),
                ),
                const SizedBox(height: 32),
                const Text('GENERAL NOTES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                const SizedBox(height: 12),
                TextField(
                  controller: _globalNotesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Any special instructions...',
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 120),
              ],
            );
          }
          return _buildOrderItemForm(index);
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: FloatingActionButton.extended(
          onPressed: _sendToWhatsApp,
          backgroundColor: const Color(0xFF25D366),
          icon: const Icon(Icons.chat_outlined, color: Colors.white),
          label: const Text('SEND TO WHATSAPP', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildOrderItemForm(int index) {
    final item = _orderItems[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFF1A237E).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Text('ITEM #${index + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
              ),
              if (_orderItems.length > 1)
                IconButton(icon: const Icon(Icons.close, color: Colors.red, size: 20), onPressed: () => _removeOrderItem(index)),
            ],
          ),
          const SizedBox(height: 20),
          
          const Text('SUPPLY & CATEGORY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _categoryPill(item, 'LENS'),
              _categoryPill(item, 'FRAME'),
              _categoryPill(item, 'BOTH'),
              _categoryPill(item, 'CONTACT LENS'),
              _categoryPill(item, 'SOLUTIONS'),
            ],
          ),
          
          const SizedBox(height: 24),
          const Text('PRODUCT SELECTION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          _isLoadingItems 
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
            : Autocomplete<Map<String, dynamic>>(
                displayStringForOption: (option) => (option['itemName'] ?? option['name'] ?? '').toString(),
                optionsBuilder: (TextEditingValue textEditingValue) {
                  final String cat = item.category.toLowerCase();
                  final filtered = _allBackendItems.where((i) {
                    final String itemCat = (i['category'] ?? '').toString().toLowerCase();
                    if (cat == 'lens' || cat == 'both') return itemCat.contains('lens') || i['isFrame'] != true;
                    if (cat == 'frame') return itemCat.contains('frame') || i['isFrame'] == true;
                    if (cat == 'contact lens') return itemCat.contains('contact');
                    if (cat == 'solutions') return itemCat.contains('solution');
                    return true;
                  });

                  if (textEditingValue.text.isEmpty) return filtered;
                  return filtered.where((i) {
                    final String name = (i['itemName'] ?? i['name'] ?? '').toString().toLowerCase();
                    return name.contains(textEditingValue.text.toLowerCase());
                  });
                },
                onSelected: (Map<String, dynamic> selected) {
                  setState(() {
                    item.selectedItemId = (selected['id'] ?? selected['_id'] ?? '').toString();
                    item.itemNameController.text = (selected['itemName'] ?? selected['name'] ?? '').toString();
                  });
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  if (item.itemNameController.text.isNotEmpty && controller.text.isEmpty) {
                    controller.text = item.itemNameController.text;
                  }
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      hintText: 'Type to search product... *',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: const Icon(Icons.arrow_drop_down),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 8,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: MediaQuery.of(context).size.width - 72, // Responsive width
                        constraints: const BoxConstraints(maxHeight: 300),
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final option = options.elementAt(index);
                            final String name = option['itemName'] ?? option['name'] ?? 'Unnamed';
                            final stock = option['stockQty'] ?? 0;
                            return ListTile(
                              title: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              subtitle: Text('Stock: $stock', style: const TextStyle(fontSize: 11)),
                              onTap: () => onSelected(option),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
          
          if (item.category == 'LENS' || item.category == 'BOTH' || item.category == 'CONTACT LENS') ...[
            const SizedBox(height: 24),
            const Text('POWER LAYOUT STRATEGY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _strategyPill(item, 'Any'),
                  _strategyPill(item, 'Single R'),
                  _strategyPill(item, 'Single L'),
                  _strategyPill(item, 'Both (Same)'),
                  _strategyPill(item, 'Both (Diff)'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildEyeGrid(item),
          ] else ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _buildQtyInput(item.rQty, 'ORDER QUANTITY')),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _categoryPill(VendorOrderItem item, String cat) {
    bool isSel = item.category == cat;
    return InkWell(
      onTap: () => setState(() => item.category = cat),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFF1A237E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSel ? const Color(0xFF1A237E) : Colors.grey.shade300),
        ),
        child: Text(cat, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSel ? Colors.white : Colors.grey[700])),
      ),
    );
  }

  Widget _strategyPill(VendorOrderItem item, String strat) {
    bool isSel = item.powerStrategy == strat;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(strat, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        selected: isSel,
        onSelected: (val) => setState(() => item.powerStrategy = strat),
        selectedColor: Colors.blue[100],
        labelStyle: TextStyle(color: isSel ? Colors.blue[900] : Colors.grey[700]),
      ),
    );
  }

  Widget _buildEyeGrid(VendorOrderItem item) {
    bool showR = item.powerStrategy != 'Single L';
    bool showL = item.powerStrategy != 'Single R' && item.powerStrategy != 'Both (Same)';
    
    return Column(
      children: [
        _eyeHeaderRow(),
        const SizedBox(height: 8),
        if (showR) _buildEyeRow(item, item.powerStrategy == 'Both (Same)' ? 'BOTH' : 'R'),
        if (showR && showL) const SizedBox(height: 8),
        if (showL) _buildEyeRow(item, 'L'),
      ],
    );
  }

  Widget _eyeHeaderRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          const Expanded(flex: 3, child: Center(child: Text('EYE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black54)))),
          _headCell('SPH RANGE'),
          _headCell('CYL RANGE'),
          const Expanded(flex: 4, child: Center(child: Text('AXIS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black54)))),
          _headCell('ADD RANGE'),
          const Expanded(flex: 3, child: Center(child: Text('QTY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black54)))),
        ],
      ),
    );
  }

  Widget _headCell(String label) => Expanded(flex: 6, child: Center(child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black54))));

  Widget _buildEyeRow(VendorOrderItem item, String eye) {
    bool isL = eye == 'L';
    TextEditingController sf = isL ? item.lSphFrom : item.rSphFrom;
    TextEditingController st = isL ? item.lSphTo : item.rSphTo;
    TextEditingController cf = isL ? item.lCylFrom : item.rCylFrom;
    TextEditingController ct = isL ? item.lCylTo : item.rCylTo;
    TextEditingController ax = isL ? item.lAxis : item.rAxis;
    TextEditingController af = isL ? item.lAddFrom : item.rAddFrom;
    TextEditingController at = isL ? item.lAddTo : item.rAddTo;
    TextEditingController q = isL ? item.lQty : item.rQty;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_box, size: 18, color: Colors.blue[900]),
                const SizedBox(width: 4),
                Text(eye, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.blue[900])),
              ],
            ),
          ),
          _rangeCell(sf, st),
          _rangeCell(cf, ct),
          Expanded(flex: 4, child: _smallField(ax, 'AXIS', isLarge: true)),
          _rangeCell(af, at),
          Expanded(flex: 3, child: _smallField(q, '1', isNum: true, isLarge: true)),
        ],
      ),
    );
  }

  Widget _rangeCell(TextEditingController f, TextEditingController t) {
    return Expanded(
      flex: 6,
      child: Column(
        children: [
          _smallField(f, 'FROM', isNum: true),
          const SizedBox(height: 4),
          _smallField(t, 'TO', isNum: true),
        ],
      ),
    );
  }

  Widget _smallField(TextEditingController ctrl, String hint, {bool isNum = false, bool isLarge = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        height: isLarge ? 84 : 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Center(
          child: TextField(
            controller: ctrl,
            keyboardType: isNum ? const TextInputType.numberWithOptions(decimal: true, signed: true) : TextInputType.text,
            textAlign: TextAlign.center,
            maxLines: isLarge ? null : 1,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(fontSize: 9, fontWeight: FontWeight.normal, color: Colors.grey.shade400),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              isDense: true,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQtyInput(TextEditingController ctrl, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Quantity',
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}

class VendorOrderItem {
  String category = 'LENS';
  String powerStrategy = 'Any';
  String? selectedItemId;
  final TextEditingController itemNameController = TextEditingController();
  
  final TextEditingController rSphFrom = TextEditingController();
  final TextEditingController rSphTo = TextEditingController();
  final TextEditingController rCylFrom = TextEditingController();
  final TextEditingController rCylTo = TextEditingController();
  final TextEditingController rAxis = TextEditingController();
  final TextEditingController rAddFrom = TextEditingController();
  final TextEditingController rAddTo = TextEditingController();
  final TextEditingController rQty = TextEditingController(text: '1');
  bool isRightSelected = true;

  final TextEditingController lSphFrom = TextEditingController();
  final TextEditingController lSphTo = TextEditingController();
  final TextEditingController lCylFrom = TextEditingController();
  final TextEditingController lCylTo = TextEditingController();
  final TextEditingController lAxis = TextEditingController();
  final TextEditingController lAddFrom = TextEditingController();
  final TextEditingController lAddTo = TextEditingController();
  final TextEditingController lQty = TextEditingController(text: '1');
  bool isLeftSelected = true;

  void dispose() {
    itemNameController.dispose();
    rSphFrom.dispose(); rSphTo.dispose(); rCylFrom.dispose(); rCylTo.dispose(); rAxis.dispose(); rAddFrom.dispose(); rAddTo.dispose(); rQty.dispose();
    lSphFrom.dispose(); lSphTo.dispose(); lCylFrom.dispose(); lCylTo.dispose(); lAxis.dispose(); lAddFrom.dispose(); lAddTo.dispose(); lQty.dispose();
  }
}
