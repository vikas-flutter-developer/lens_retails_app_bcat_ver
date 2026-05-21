import 'package:flutter/material.dart';
import '../services/job_card_service.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class JobCardsListScreen extends StatefulWidget {
  const JobCardsListScreen({super.key});

  @override
  State<JobCardsListScreen> createState() => _JobCardsListScreenState();
}

class _JobCardsListScreenState extends State<JobCardsListScreen> {
  final JobCardService _jobCardService = JobCardService();
  List<dynamic> _jobCards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchJobCards();
  }

  Future<void> _fetchJobCards() async {
    setState(() => _isLoading = true);
    try {
      final cards = await _jobCardService.getAllJobCards();
      setState(() {
        _jobCards = cards ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error loading job cards: $e', isError: true);
    }
  }

  Future<void> _deleteCard(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Job Card'),
        content: const Text('Are you sure you want to permanently delete this job card?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final ok = await _jobCardService.deleteCompleteJobCard(id);
    if (ok) {
      _showSnackBar('Job Card deleted successfully!');
      _fetchJobCards();
    } else {
      _showSnackBar('Failed to delete Job Card', isError: true);
    }
  }

  Future<void> _updateStatus(dynamic card, String newStatus) async {
    final res = await _jobCardService.patchJobCardStatus(card['id'], newStatus);
    if (res != null) {
      _showSnackBar('Status updated to $newStatus!');
      _fetchJobCards();
      // Auto-trigger WhatsApp notification for status change!
      _launchWhatsApp(card, newStatus);
    } else {
      _showSnackBar('Failed to update status', isError: true);
    }
  }

  void _showAddPaymentDialog(dynamic card) {
    final String id = card['id'];
    final double totalAmount = double.tryParse(card['totalAmount']?.toString() ?? '0') ?? 0.0;
    final double paidAmount = double.tryParse(card['paidAmount']?.toString() ?? '0') ?? 0.0;
    final double dueAmount = double.tryParse(card['dueAmount']?.toString() ?? '0') ?? 0.0;

    final controller = TextEditingController();
    String selectedMode = 'CASH';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final double halfPayment = (dueAmount / 2).roundToDouble();

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            clipBehavior: Clip.antiAlias,
            backgroundColor: Colors.white,
            child: Container(
              width: 440,
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Section
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A237E).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF1A237E), size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Collect Payment',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Balance Status Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total Bill:', style: TextStyle(color: Colors.grey.shade600, fontSize: 13.5)),
                              Text('₹${totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total Paid:', style: TextStyle(color: Colors.grey.shade600, fontSize: 13.5)),
                              Text('₹${paidAmount.toStringAsFixed(0)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 14)),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Pending Balance:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
                              Text('₹${dueAmount.toStringAsFixed(0)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 17)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Quick Payment Buttons
                    const Text(
                      'Quick Presets:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        // Full Payment Button
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                controller.text = dueAmount.toStringAsFixed(0);
                              });
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              decoration: BoxDecoration(
                                color: controller.text == dueAmount.toStringAsFixed(0)
                                    ? const Color(0xFF1A237E).withOpacity(0.08)
                                    : Colors.white,
                                border: Border.all(
                                  color: controller.text == dueAmount.toStringAsFixed(0)
                                      ? const Color(0xFF1A237E)
                                      : Colors.grey.shade300,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'FULL PAYMENT',
                                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFF1A237E), letterSpacing: 0.5),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₹${dueAmount.toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Half Payment Button
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                controller.text = halfPayment.toStringAsFixed(0);
                              });
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              decoration: BoxDecoration(
                                color: controller.text == halfPayment.toStringAsFixed(0)
                                    ? const Color(0xFF1A237E).withOpacity(0.08)
                                    : Colors.white,
                                border: Border.all(
                                  color: controller.text == halfPayment.toStringAsFixed(0)
                                      ? const Color(0xFF1A237E)
                                      : Colors.grey.shade300,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'HALF PAYMENT',
                                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFF1A237E), letterSpacing: 0.5),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₹${halfPayment.toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Amount Input Field
                    TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      onChanged: (val) {
                        setState(() {}); // trigger rebuild to update quick-preset highlights
                      },
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                      decoration: InputDecoration(
                        labelText: 'Payment Amount Collected (₹)',
                        labelStyle: const TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.bold),
                        prefixText: '₹ ',
                        prefixStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF1A237E), width: 1.8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Payment Mode Dropdown
                    const Text(
                      'Payment Mode:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedMode,
                      decoration: InputDecoration(
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
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'CASH', child: Row(children: [Icon(Icons.money_outlined, size: 18), SizedBox(width: 8), Text('Cash')])),
                        DropdownMenuItem(value: 'UPI', child: Row(children: [Icon(Icons.qr_code_2, size: 18), SizedBox(width: 8), Text('UPI / QR Scan')])),
                        DropdownMenuItem(value: 'CARD', child: Row(children: [Icon(Icons.credit_card_outlined, size: 18), SizedBox(width: 8), Text('Card Payment')])),
                      ],
                      onChanged: (val) => setState(() => selectedMode = val ?? 'CASH'),
                    ),
                    const SizedBox(height: 32),

                    // Footer Buttons
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey.shade600,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('CANCEL', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () async {
                              final amount = double.tryParse(controller.text) ?? 0.0;
                              if (amount <= 0) {
                                _showSnackBar('Please enter a valid amount', isError: true);
                                return;
                              }
                              if (amount > dueAmount) {
                                _showSnackBar('Entered amount ₹$amount exceeds remaining due ₹${dueAmount.toStringAsFixed(0)}', isError: true);
                                return;
                              }
                              final key = 'key_${DateTime.now().millisecondsSinceEpoch}';
                              final res = await _jobCardService.addPaymentToJobCard(id, {
                                'amount': amount,
                                'paymentType': selectedMode,
                                'idempotencyKey': key,
                              });
                              if (mounted) Navigator.pop(context);
                              if (res != null) {
                                _showSnackBar('Payment of ₹$amount collected successfully!');
                                _fetchJobCards();
                                // Trigger payment receipt notification on WhatsApp!
                                _launchWhatsApp(card, 'PaymentReceived');
                              } else {
                                _showSnackBar('Failed to process payment', isError: true);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A237E),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('SUBMIT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _launchWhatsApp(dynamic card, String status) async {
    final customer = card['customer'] as Map? ?? {};
    final String name = customer['fullName'] ?? card['customerId'] ?? 'Customer';
    final String mobile = customer['phone'] ?? '';
    final String billNo = card['billNo'] ?? (card['id'] != null ? card['id'].toString().substring(0, 8) : 'N/A');
    
    if (mobile.isEmpty) {
      _showSnackBar('Customer mobile number not found', isError: true);
      return;
    }

    String message = "";
    if (status == 'IN_PROGRESS') {
      message = "Hello $name,\n\nYour optical order (Bill No: $billNo) is now IN PROGRESS! 🛠️✨\n\nYour lenses are being carefully processed by our lab. We will notify you as soon as they are ready for collection.\n\nThank you for choosing Retail Lens! 👓";
    } else if (status == 'READY') {
      message = "Hello $name,\n\nYour optical order (Bill No: $billNo) is now READY for collection! 👓✨\n\nPlease visit our store to collect your new eyewear.\n\nThank you for choosing Retail Lens!";
    } else if (status == 'DELIVERED') {
      message = "Hello $name,\n\nYour optical order (Bill No: $billNo) has been successfully DELIVERED! ✅\n\nThank you for your business! We hope you love your new glasses! 👓✨";
    } else if (status == 'PaymentReceived') {
      final double paid = double.tryParse(card['paidAmount']?.toString() ?? '0') ?? 0.0;
      final double due = double.tryParse(card['dueAmount']?.toString() ?? '0') ?? 0.0;
      message = "Hello $name,\n\nWe have received your payment for order $billNo. ✅\n\nTotal Paid: ₹$paid\nRemaining Balance: ₹$due\n\nThank you, Retail Lens! 👓✨";
    } else if (status == 'BalanceReminder') {
      final String balance = card['dueAmount']?.toString() ?? '0';
      message = "Hello $name,\n\nThis is a friendly reminder regarding your optical order $billNo. 👓\n\nA pending balance payment of ₹$balance is due. You can pay this at the time of collection.\n\nThank you, Retail Lens!";
    } else if (status == 'Invoice') {
      final items = card['items'] as List? ?? [];
      final double total = double.tryParse(card['totalAmount']?.toString() ?? '0') ?? 0.0;
      final double paid = double.tryParse(card['paidAmount']?.toString() ?? '0') ?? 0.0;
      final double due = double.tryParse(card['dueAmount']?.toString() ?? '0') ?? 0.0;
      
      final String itemsStr = items.map((it) {
        final desc = it['description'] ?? it['itemName'] ?? 'Product';
        final qty = it['quantity'] ?? it['qty'] ?? 1;
        final price = it['unitPrice'] ?? it['salePrice'] ?? 0;
        return "• $desc (x$qty) - ₹$price";
      }).join('\n');

      message = "*RETAIL LENS OPTICALS*\n"
          "Premium Lens & Eyewear Solutions\n\n"
          "Hello $name,\n"
          "Here are your invoice details for Bill No: *$billNo* 📄✨\n\n"
          "*ITEMS ORDERED:*\n$itemsStr\n\n"
          "*PAYMENT SUMMARY:*\n"
          "• Total Amount: ₹${total.toStringAsFixed(0)}\n"
          "• Total Paid: ₹${paid.toStringAsFixed(0)}\n"
          "*• DUE BALANCE: ₹${due.toStringAsFixed(0)}*\n\n"
          "Thank you for choosing Retail Lens! 👓✨";
    } else if (status == 'CANCELLED') {
      message = "Hello $name,\n\nYour optical order (Bill No: $billNo) has been CANCELLED. ❌\n\nIf you have any questions, please contact our store. Thank you, Retail Lens.";
    } else {
      message = "Hello $name, your optical order (Bill No: $billNo) has been updated to: $status. Thank you, Retail Lens.";
    }
    
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
      _showSnackBar('Error opening WhatsApp: $e', isError: true);
    }
  }

  Future<void> _selectExpectedCompletionDate(dynamic card) async {
    final String id = card['id'];
    final String? currentExpected = card['expectedCompletionDate'];
    DateTime initialDate = DateTime.now().add(const Duration(days: 3));
    
    if (currentExpected != null && currentExpected.isNotEmpty) {
      try {
        initialDate = DateTime.parse(currentExpected);
      } catch (_) {}
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Colors.blue,
            onPrimary: Colors.white,
            onSurface: Colors.black87,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      final res = await _jobCardService.updateJobCard(id, {
        'expectedCompletionDate': picked.toIso8601String(),
      });
      if (res != null) {
        _showSnackBar('Lab Target Date updated successfully!');
        _fetchJobCards();
      } else {
        _showSnackBar('Failed to update Lab Target Date', isError: true);
      }
    }
  }

  void _showAddItemDialog(String id) {
    final descController = TextEditingController();
    final qtyController = TextEditingController(text: '1');
    final priceController = TextEditingController();
    final sphController = TextEditingController();
    final cylController = TextEditingController();
    final axisController = TextEditingController();
    final addController = TextEditingController();
    String eye = 'RIGHT';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Item to Job Card'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description (e.g. Lens, Frame)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: qtyController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Quantity', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Price (₹)', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                const Text('Prescription (Optional)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: TextField(controller: sphController, decoration: const InputDecoration(labelText: 'SPH', border: OutlineInputBorder()))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: cylController, decoration: const InputDecoration(labelText: 'CYL', border: OutlineInputBorder()))),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: TextField(controller: axisController, decoration: const InputDecoration(labelText: 'AXIS', border: OutlineInputBorder()))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: addController, decoration: const InputDecoration(labelText: 'ADD', border: OutlineInputBorder()))),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: eye,
                  decoration: const InputDecoration(labelText: 'Eye Side', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'RIGHT', child: Text('Right Eye')),
                    DropdownMenuItem(value: 'LEFT', child: Text('Left Eye')),
                    DropdownMenuItem(value: 'BOTH', child: Text('Both Eyes')),
                  ],
                  onChanged: (val) => setState(() => eye = val ?? 'RIGHT'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (descController.text.isEmpty) {
                  _showSnackBar('Description is required', isError: true);
                  return;
                }
                final qty = int.tryParse(qtyController.text) ?? 1;
                final price = double.tryParse(priceController.text) ?? 0.0;
                final payload = {
                  'description': descController.text,
                  'quantity': qty,
                  'unitPrice': price,
                  'lineTotal': qty * price,
                  'sph': sphController.text.isEmpty ? null : sphController.text,
                  'cyl': cylController.text.isEmpty ? null : cylController.text,
                  'axis': axisController.text.isEmpty ? null : axisController.text,
                  'add': addController.text.isEmpty ? null : addController.text,
                  'eye': eye,
                };
                final res = await _jobCardService.addItemToJobCard(id, payload);
                if (mounted) Navigator.pop(context);
                if (res != null) {
                  _showSnackBar('Item added successfully!');
                  _fetchJobCards();
                } else {
                  _showSnackBar('Failed to add item', isError: true);
                }
              },
              child: const Text('Add Item'),
            )
          ],
        ),
      ),
    );
  }

  void _showNativeInvoiceDialog(dynamic card) {
    final String billNoRaw = card['billNo'] ?? 'No Bill';
    // 💎 Generate premium, user-friendly formatted receipt number
    final String billNo = billNoRaw.length > 10 
        ? 'INV-${billNoRaw.substring(billNoRaw.length - 6).toUpperCase()}' 
        : billNoRaw;
    final String customerId = card['customerId'] ?? 'Walk-In';
    final String status = card['status'] ?? 'DRAFT';
    final double totalAmount = double.tryParse(card['totalAmount']?.toString() ?? '0') ?? 0.0;
    final double paidAmount = double.tryParse(card['paidAmount']?.toString() ?? '0') ?? 0.0;
    final double dueAmount = double.tryParse(card['dueAmount']?.toString() ?? '0') ?? 0.0;
    final String dateStr = card['createdAt'] != null 
        ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(card['createdAt'])) 
        : 'N/A';

    final itemsList = card['items'] as List? ?? [];
    final paymentsList = card['payments'] as List? ?? [];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const Center(
                  child: Column(
                    children: [
                      Icon(Icons.remove_red_eye, color: Colors.blue, size: 40),
                      SizedBox(height: 8),
                      Text(
                        'RETAIL LENS OPTICALS',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.2),
                      ),
                      Text(
                        'Premium Lens & Eyewear Solutions',
                        style: TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Dotted Divider
                _buildDottedLine(),
                const SizedBox(height: 12),

                // Bill Metadata
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Bill No: $billNo', 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(status, style: const TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Customer: $customerId', style: const TextStyle(color: Colors.black87, fontSize: 13)),
                const SizedBox(height: 4),
                Text('Date: $dateStr', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                
                const SizedBox(height: 12),
                _buildDottedLine(),
                const SizedBox(height: 12),

                // Items list
                const Text('ORDER ITEMS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey, letterSpacing: 1.1)),
                const SizedBox(height: 8),
                ...itemsList.map((item) {
                  final desc = item['description'] ?? 'Unnamed Item';
                  final qty = item['quantity'] ?? 1;
                  final total = double.tryParse(item['lineTotal']?.toString() ?? '0') ?? 0.0;
                  final powerInfo = item['sph'] != null ? 'SPH: ${item['sph']} | CYL: ${item['cyl']} | Eye: ${item['eye']}' : '';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text('$desc (x$qty)', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                            Text('₹${total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                        if (powerInfo.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Text(powerInfo, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                          ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 12),
                _buildDottedLine(),
                const SizedBox(height: 12),

                // Payments list
                if (paymentsList.isNotEmpty) ...[
                  const Text('PAYMENTS RECEIVED', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey, letterSpacing: 1.1)),
                  const SizedBox(height: 8),
                  ...paymentsList.map((p) {
                    final amt = double.tryParse(p['amount']?.toString() ?? '0') ?? 0.0;
                    final type = p['paymentType'] ?? 'CASH';
                    final pDate = p['createdAt'] != null
                        ? DateFormat('dd MMM').format(DateTime.parse(p['createdAt']))
                        : '';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('• $type Payment ($pDate)', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                          Text('₹${amt.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.green)),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  _buildDottedLine(),
                  const SizedBox(height: 12),
                ],

                // Totals
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount:', style: TextStyle(fontSize: 13, color: Colors.grey)),
                    Text('₹${totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Paid:', style: TextStyle(fontSize: 13, color: Colors.grey)),
                    Text('₹${paidAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('DUE BALANCE:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    Text('₹${dueAmount.toStringAsFixed(0)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: dueAmount > 0 ? Colors.red : Colors.green)),
                  ],
                ),

                const SizedBox(height: 20),
                const Center(
                  child: Column(
                    children: [
                      Text('Thank you for choosing Lens Retail! 👓✨', style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic)),
                      SizedBox(height: 16),
                    ],
                  ),
                ),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _launchWhatsApp(card, 'Invoice');
                        },
                        icon: const Icon(Icons.share, color: Colors.white, size: 16),
                        label: const Text('Share Invoice', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Close Receipt', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
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

  void _showSnackBar(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
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
                        child: const Text('Create New Job Card'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _jobCards.length,
                  itemBuilder: (context, index) {
                    final card = _jobCards[index];
                    return _buildJobCardItem(card);
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

  Widget _buildJobCardItem(dynamic card) {
    final String id = card['id'] ?? 'N/A';
    final String customerId = card['customerId'] ?? 'Walk-In';
    final String status = card['status'] ?? 'DRAFT';
    final double totalAmount = double.tryParse(card['totalAmount']?.toString() ?? '0') ?? 0.0;
    final double paidAmount = double.tryParse(card['paidAmount']?.toString() ?? '0') ?? 0.0;
    final double dueAmount = double.tryParse(card['dueAmount']?.toString() ?? '0') ?? 0.0;
    final String billNo = card['billNo'] ?? 'No Bill';

    final customer = card['customer'] as Map? ?? {};
    final String customerName = customer['fullName'] ?? customerId;

    final itemsList = card['items'] as List? ?? [];
    final paymentsList = card['payments'] as List? ?? [];

    final String? expectedDateStr = card['expectedCompletionDate'];
    Widget deadlineWidget = Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: InkWell(
        onTap: () => _selectExpectedCompletionDate(card),
        borderRadius: BorderRadius.circular(4),
        child: const Text(
          '📅 Set Lab Target Date',
          style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.w500, decoration: TextDecoration.underline),
        ),
      ),
    );

    if (expectedDateStr != null && expectedDateStr.isNotEmpty) {
      try {
        final expectedDate = DateTime.parse(expectedDateStr);
        final difference = expectedDate.difference(DateTime.now()).inDays;
        final formattedExpected = DateFormat('dd MMM yyyy').format(expectedDate);

        Widget textWidget;
        if (difference < 0) {
          textWidget = Text(
            '⚠️ Overdue by ${difference.abs()} days ($formattedExpected) ✎',
            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
          );
        } else if (difference == 0) {
          textWidget = Text(
            '🔥 Due TODAY ($formattedExpected) ✎',
            style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
          );
        } else {
          textWidget = Text(
            '📅 Lab Target: $formattedExpected (Due in $difference days) ✎',
            style: const TextStyle(color: Colors.blueGrey, fontSize: 12, fontWeight: FontWeight.w500),
          );
        }

        deadlineWidget = Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: InkWell(
            onTap: () => _selectExpectedCompletionDate(card),
            borderRadius: BorderRadius.circular(4),
            child: textWidget,
          ),
        );
      } catch (_) {}
    }

    Color statusColor;
    switch (status) {
      case 'DRAFT':
        statusColor = Colors.orange;
        break;
      case 'IN_PROGRESS':
        statusColor = Colors.blue;
        break;
      case 'READY':
        statusColor = Colors.teal;
        break;
      case 'DELIVERED':
        statusColor = Colors.green;
        break;
      case 'RETURNED':
        statusColor = Colors.purple;
        break;
      case 'CANCELLED':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Customer: $customerName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('Bill: $billNo', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  deadlineWidget,
                ],
              ),
            ),
            _buildStatusBadge(status, statusColor),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total: ₹${totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600)),
              Text('Due: ₹${dueAmount.toStringAsFixed(0)}', style: TextStyle(color: dueAmount > 0 ? Colors.red : Colors.green, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        children: [
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fast Status Toggles
                const Text('Update Status:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _buildStatusChip(card, 'DRAFT', status),
                    _buildStatusChip(card, 'IN_PROGRESS', status),
                    _buildStatusChip(card, 'READY', status),
                    _buildStatusChip(card, 'DELIVERED', status),
                    _buildStatusChip(card, 'RETURNED', status),
                  ],
                ),
                const Divider(height: 24),

                // Items list
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Items (${itemsList.length}):', style: const TextStyle(fontWeight: FontWeight.bold)),
                    TextButton.icon(
                      onPressed: () => _showAddItemDialog(id),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Item', style: TextStyle(fontSize: 12)),
                    )
                  ],
                ),
                if (itemsList.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('No items added to this card', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  )
                else
                  ...itemsList.map((item) {
                    final itemId = item['id'];
                    final desc = item['description'] ?? 'Unnamed Item';
                    final price = double.tryParse(item['unitPrice']?.toString() ?? '0') ?? 0.0;
                    final qty = item['quantity'] ?? 1;
                    final total = double.tryParse(item['lineTotal']?.toString() ?? '0') ?? 0.0;
                    final powerInfo = item['sph'] != null ? 'SPH: ${item['sph']} | CYL: ${item['cyl']} | Eye: ${item['eye']}' : '';

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('$desc (x$qty)', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      subtitle: Text(powerInfo.isNotEmpty ? '₹$price | $powerInfo' : '₹$price'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('₹${total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            onPressed: () async {
                              final ok = await _jobCardService.removeItemFromJobCard(id, itemId);
                              if (ok) {
                                _showSnackBar('Item removed successfully!');
                                _fetchJobCards();
                              } else {
                                _showSnackBar('Failed to remove item', isError: true);
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  }),

                const Divider(height: 24),

                // Payments list
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Payments (${paymentsList.length}):', style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (dueAmount > 0)
                      TextButton.icon(
                        onPressed: () => _showAddPaymentDialog(card),
                        icon: const Icon(Icons.payment, size: 16),
                        label: const Text('Add Payment', style: TextStyle(fontSize: 12)),
                      )
                  ],
                ),
                if (paymentsList.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('No payments recorded yet', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  )
                else
                  ...paymentsList.map((p) {
                    final paymentId = p['id'];
                    final amt = double.tryParse(p['amount']?.toString() ?? '0') ?? 0.0;
                    final type = p['paymentType'] ?? 'CASH';

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                      title: Text('Payment ₹${amt.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14)),
                      subtitle: Text('Mode: $type'),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                        tooltip: 'Void Payment',
                        onPressed: () async {
                          final ok = await _jobCardService.deletePaymentFromJobCard(id, paymentId);
                          if (ok) {
                            _showSnackBar('Payment voided/deleted successfully!');
                            _fetchJobCards();
                          } else {
                            _showSnackBar('Failed to void payment', isError: true);
                          }
                        },
                      ),
                    );
                  }),

                const Divider(height: 24),

                // Card Footer Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _showNativeInvoiceDialog(card),
                      icon: const Icon(Icons.receipt_long, size: 16),
                      label: const Text('View Invoice'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                    ),
                    if (dueAmount > 0)
                      ElevatedButton.icon(
                        onPressed: () => _launchWhatsApp(card, 'BalanceReminder'),
                        icon: const Icon(Icons.notifications_active, size: 16),
                        label: const Text('Reminder'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[800], foregroundColor: Colors.white),
                      ),
                    IconButton(
                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                      tooltip: 'Delete Job Card',
                      onPressed: () => _deleteCard(id),
                    ),
                  ],
                )
              ],
            ),
          )
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
      child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  Widget _buildStatusChip(dynamic card, String targetStatus, String currentStatus) {
    final bool isCurrent = currentStatus == targetStatus;
    
    Color selectedColor = Colors.blue;
    if (targetStatus == 'DRAFT') selectedColor = Colors.orange;
    else if (targetStatus == 'IN_PROGRESS') selectedColor = Colors.blue;
    else if (targetStatus == 'READY') selectedColor = Colors.teal;
    else if (targetStatus == 'DELIVERED') selectedColor = Colors.green;
    else if (targetStatus == 'RETURNED') selectedColor = Colors.purple;

    return ChoiceChip(
      label: Text(targetStatus, style: TextStyle(color: isCurrent ? Colors.white : Colors.black87, fontSize: 11)),
      selected: isCurrent,
      selectedColor: selectedColor,
      onSelected: (selected) {
        if (!isCurrent) _updateStatus(card, targetStatus);
      },
    );
  }
}
