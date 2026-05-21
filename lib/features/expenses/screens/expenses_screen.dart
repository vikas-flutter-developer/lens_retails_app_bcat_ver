import 'package:flutter/material.dart';
import '../services/expense_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final ExpenseService _expenseService = ExpenseService();
  List<Map<String, dynamic>> _expenses = [];
  bool _isLoading = true;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchExpenses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchExpenses() async {
    setState(() => _isLoading = true);
    try {
      final data = await _expenseService.fetchExpenses(period: 'year');
      setState(() {
        _expenses = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading expenses: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFC62828),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFC62828),
              ),
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
  void _shareCompletePeriodReport() async {
    final filtered = _filteredExpenses;
    if (filtered.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No expenses to share')),
      );
      return;
    }

    final double total = filtered.fold<double>(0, (sum, item) => sum + (item['amount'] ?? 0.0));
    
    final StringBuffer buffer = StringBuffer();
    buffer.writeln("*RETAIL LENS EXPENSE REPORT* 📊");
    final String dateRangeStr = "${_startDate.day}/${_startDate.month}/${_startDate.year} to ${_endDate.day}/${_endDate.month}/${_endDate.year}";
    buffer.writeln("📅 *Period:* $dateRangeStr");
    buffer.writeln("━━━━━━━━━━━━━━━━━━━━");
    
    for (var exp in filtered) {
      final String category = exp['category'] ?? 'Misc';
      final double amt = (exp['amount'] as num?)?.toDouble() ?? 0.0;
      final String date = exp['date'] ?? '';
      final String mode = exp['paymentMode']?.toString().toUpperCase() ?? 'CASH';
      buffer.writeln("• *₹$amt* - $category [$mode] ($date)");
      if (exp['note'] != null && exp['note'].toString().isNotEmpty) {
        buffer.writeln("  _Note: ${exp['note']}_");
      }
    }
    
    buffer.writeln("━━━━━━━━━━━━━━━━━━━━");
    buffer.writeln("💰 *TOTAL EXPENSE:* *₹${total.toStringAsFixed(2)}*");
    buffer.writeln("\nSent via Lens Retail App 👓✨");

    final Uri url = Uri.parse("https://wa.me/919822334455?text=${Uri.encodeComponent(buffer.toString())}");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch WhatsApp')),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredExpenses {
    final now = DateTime.now();
    return _expenses.where((ex) {
      // 1. Filter by Date
      final dateParts = ex['date'].split('-');
      if (dateParts.length != 3) return true;
      final dt = DateTime(int.parse(dateParts[2]), int.parse(dateParts[1]), int.parse(dateParts[0]));
      
      final startMidnight = DateTime(_startDate.year, _startDate.month, _startDate.day);
      final endMidnight = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);
      
      final bool dateMatch = dt.isAfter(startMidnight.subtract(const Duration(seconds: 1))) && 
                             dt.isBefore(endMidnight.add(const Duration(seconds: 1)));

      if (!dateMatch) return false;

      // 2. Filter by Search Query
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      final category = (ex['category'] ?? '').toString().toLowerCase();
      final note = (ex['note'] ?? '').toString().toLowerCase();
      
      return category.contains(query) || note.contains(query);
    }).toList();
  }

  void _showAddEditExpenseSheet({Map<String, dynamic>? expense}) {
    final bool isEdit = expense != null;
    final TextEditingController categoryController = TextEditingController(text: isEdit ? expense['category'] : '');
    final TextEditingController amountController = TextEditingController(text: isEdit ? expense['amount']?.toString() : '');
    final TextEditingController noteController = TextEditingController(text: isEdit ? expense['note'] : '');
    String selectedMode = isEdit ? (expense['paymentMode'] ?? 'CASH').toString().toUpperCase() : 'CASH';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    isEdit ? 'Edit Expense' : 'Add New Expense',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFC62828)),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: categoryController,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      hintText: 'e.g. Rent, Salary, Tea',
                      prefixIcon: const Icon(Icons.category_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Amount (₹)',
                      hintText: '0.00',
                      prefixIcon: const Icon(Icons.currency_rupee),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: noteController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Description / Note',
                      hintText: 'Add some details...',
                      prefixIcon: const Icon(Icons.note_alt_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Payment Mode',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setModalState(() {
                              selectedMode = 'CASH';
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: selectedMode == 'CASH'
                                  ? const Color(0xFFC62828).withValues(alpha: 0.1)
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selectedMode == 'CASH'
                                    ? const Color(0xFFC62828)
                                    : Colors.grey.shade300,
                                width: selectedMode == 'CASH' ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.money_rounded,
                                  color: selectedMode == 'CASH'
                                      ? const Color(0xFFC62828)
                                      : Colors.grey.shade600,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Cash',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: selectedMode == 'CASH'
                                        ? const Color(0xFFC62828)
                                        : Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setModalState(() {
                              selectedMode = 'ONLINE';
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: selectedMode == 'ONLINE'
                                  ? const Color(0xFFC62828).withValues(alpha: 0.1)
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selectedMode == 'ONLINE'
                                    ? const Color(0xFFC62828)
                                    : Colors.grey.shade300,
                                width: selectedMode == 'ONLINE' ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.devices_rounded,
                                  color: selectedMode == 'ONLINE'
                                      ? const Color(0xFFC62828)
                                      : Colors.grey.shade600,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Online',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: selectedMode == 'ONLINE'
                                        ? const Color(0xFFC62828)
                                        : Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC62828),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        if (categoryController.text.isNotEmpty && amountController.text.isNotEmpty) {
                          try {
                            if (isEdit) {
                              await _expenseService.updateExpense(expense['id'], {
                                'category': categoryController.text,
                                'amount': double.tryParse(amountController.text) ?? 0.0,
                                'note': noteController.text,
                                'paymentMode': selectedMode,
                              });
                            } else {
                              await _expenseService.createExpense({
                                'category': categoryController.text,
                                'amount': double.tryParse(amountController.text) ?? 0.0,
                                'note': noteController.text,
                                'paymentMode': selectedMode,
                              });
                            }
                            if (mounted) {
                              Navigator.pop(ctx);
                              _fetchExpenses();
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        }
                      },
                      child: Text(isEdit ? 'Update Expense' : 'Save Expense', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _shareExpenseToOwner(Map<String, dynamic> expense) async {
    final String category = expense['category'] ?? 'Misc';
    final String amount = expense['amount']?.toString() ?? '0.00';
    final String note = expense['note'] ?? '';
    final String date = expense['date'] ?? '';
    final String mode = expense['paymentMode']?.toString().toUpperCase() ?? 'CASH';

    final String message = "*RETAIL LENS EXPENSE REPORT*\n\n"
        "📅 *Date:* $date\n"
        "📂 *Category:* $category\n"
        "💳 *Mode:* $mode\n"
        "💰 *Amount:* ₹$amount\n"
        "📝 *Note:* $note\n\n"
        "Sent via Lens Retail App 👓✨";

    final Uri url = Uri.parse("https://wa.me/919822334455?text=${Uri.encodeComponent(message)}");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch WhatsApp')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredExpenses;
    final totalAmount = filtered.fold<double>(0, (sum, item) => sum + item['amount']);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Expenses', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFC62828),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: _shareCompletePeriodReport,
            tooltip: 'Share Report',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchExpenses,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            decoration: const BoxDecoration(
              color: Color(0xFFC62828),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Expenses:', style: TextStyle(color: Colors.white70, fontSize: 16)),
                    Text(
                      '₹${totalAmount.toStringAsFixed(2)}', 
                      style: const TextStyle(color: Colors.amber, fontSize: 28, fontWeight: FontWeight.bold)
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Calendar Date Range Picker Card
                GestureDetector(
                  onTap: _selectDateRange,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              "${_startDate.day}/${_startDate.month}/${_startDate.year}  -  ${_endDate.day}/${_endDate.month}/${_endDate.year}",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                        const Icon(Icons.arrow_drop_down_rounded, color: Colors.white, size: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search expenses...',
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFC62828)),
                suffixIcon: _searchQuery.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchQuery.isNotEmpty ? Icons.search_off_rounded : Icons.inventory_2_outlined, 
                          size: 64, 
                          color: Colors.grey[300]
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty 
                            ? 'No expenses match "$_searchQuery"'
                            : 'No expenses found for this period.', 
                          style: TextStyle(color: Colors.grey[500])
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final ex = filtered[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.money_off_rounded, color: Colors.red, size: 24),
                          ),
                          title: Text(ex['category'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(ex['date'] ?? '', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: (ex['paymentMode']?.toString().toUpperCase() == 'ONLINE')
                                            ? Colors.blue.shade50
                                            : Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        ex['paymentMode']?.toString().toUpperCase() ?? 'CASH',
                                        style: TextStyle(
                                          color: (ex['paymentMode']?.toString().toUpperCase() == 'ONLINE')
                                              ? Colors.blue.shade700
                                              : Colors.green.shade700,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (ex['note'] != null && ex['note'].toString().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    ex['note'],
                                    style: TextStyle(color: Colors.grey[500], fontSize: 12, fontStyle: FontStyle.italic),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '- ₹${ex['amount']}', 
                                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert_rounded, color: Colors.grey),
                                onSelected: (value) async {
                                  if (value == 'edit') {
                                    _showAddEditExpenseSheet(expense: ex);
                                  } else if (value == 'delete') {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Delete Expense'),
                                        content: const Text('Are you sure you want to delete this expense?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, true),
                                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      try {
                                        await _expenseService.deleteExpense(ex['id']);
                                        _fetchExpenses();
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Failed to delete: $e'), backgroundColor: Colors.red),
                                          );
                                        }
                                      }
                                    }
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit_outlined, size: 18, color: Colors.blue),
                                        SizedBox(width: 8),
                                        Text('Edit'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Delete'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditExpenseSheet(),
        backgroundColor: const Color(0xFFC62828),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

