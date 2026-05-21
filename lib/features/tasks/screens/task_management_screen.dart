import 'package:flutter/material.dart';
import '../services/task_service.dart';
import 'package:intl/intl.dart';
import '../../orders/services/order_service.dart';

class TaskManagementScreen extends StatefulWidget {
  final String? initialStaffId;
  const TaskManagementScreen({super.key, this.initialStaffId});

  @override
  State<TaskManagementScreen> createState() => _TaskManagementScreenState();
}

class _TaskManagementScreenState extends State<TaskManagementScreen> {
  final TaskService _taskService = TaskService();
  final OrderService _orderService = OrderService();
  List<dynamic> _tasks = [];
  List<dynamic> _staffList = [];
  bool _isLoading = true;

  // Filtering and Sorting States
  String _selectedStatusFilter = 'ALL'; // 'ALL', 'PENDING', 'IN_PROGRESS', 'COMPLETED'
  String _selectedPriorityFilter = 'ALL'; // 'ALL', 'HIGH', 'MEDIUM', 'LOW'
  String _selectedStaffFilter = 'ALL'; // 'ALL' or staffId
  String _sortBy = 'DATE_DESC'; // 'DATE_DESC', 'DATE_ASC', 'PRIORITY_HIGH', 'PRIORITY_LOW', 'TITLE_AZ'

  @override
  void initState() {
    super.initState();
    if (widget.initialStaffId != null) {
      _selectedStaffFilter = widget.initialStaffId!;
    }
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    try {
      final tasks = await _taskService.fetchTasks();
      final staff = await _taskService.fetchStaff();
      setState(() {
        _tasks = tasks;
        _staffList = staff;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<dynamic> get _filteredAndSortedTasks {
    List<dynamic> filtered = List.from(_tasks);

    // 1. Status Filter
    if (_selectedStatusFilter != 'ALL') {
      filtered = filtered.where((t) {
        final status = (t['status'] ?? '').toString().toUpperCase();
        return status == _selectedStatusFilter;
      }).toList();
    }

    // 2. Priority Filter
    if (_selectedPriorityFilter != 'ALL') {
      filtered = filtered.where((t) {
        final priority = _getDynamicPriority(t);
        return priority == _selectedPriorityFilter;
      }).toList();
    }

    // 3. Staff Filter
    if (_selectedStaffFilter != 'ALL') {
      filtered = filtered.where((t) {
        String staffId = '';
        if (t['assignedTo'] is Map) {
          staffId = (t['assignedTo']['id'] ?? t['assignedTo']['_id'] ?? t['assignedToId'] ?? '').toString();
        } else {
          staffId = (t['assignedToId'] ?? '').toString();
        }
        return staffId == _selectedStaffFilter;
      }).toList();
    }

    // 4. Sorting
    filtered.sort((a, b) {
      if (_sortBy == 'TITLE_AZ') {
        final String titleA = (a['title'] ?? '').toString().toLowerCase();
        final String titleB = (b['title'] ?? '').toString().toLowerCase();
        return titleA.compareTo(titleB);
      } else if (_sortBy == 'PRIORITY_HIGH') {
        final int pA = _getPriorityValue(_getDynamicPriority(a));
        final int pB = _getPriorityValue(_getDynamicPriority(b));
        return pB.compareTo(pA);
      } else if (_sortBy == 'PRIORITY_LOW') {
        final int pA = _getPriorityValue(_getDynamicPriority(a));
        final int pB = _getPriorityValue(_getDynamicPriority(b));
        return pA.compareTo(pB);
      } else if (_sortBy == 'DATE_ASC') {
        final String dateA = (a['dueDate'] ?? '').toString();
        final String dateB = (b['dueDate'] ?? '').toString();
        return dateA.compareTo(dateB);
      } else {
        // Default: DATE_DESC (Newest / Latest first)
        final String dateA = (a['dueDate'] ?? '').toString();
        final String dateB = (b['dueDate'] ?? '').toString();
        return dateB.compareTo(dateA);
      }
    });

    return filtered;
  }

  int _getDaysRemaining(dynamic dueDateStr) {
    if (dueDateStr == null) return 999;
    final String str = dueDateStr.toString().trim().toLowerCase();
    if (str == 'today') return 0;
    if (str == 'tomorrow') return 1;
    if (str == 'yesterday') return -1;
    
    final parsed = DateTime.tryParse(str);
    if (parsed != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final due = DateTime(parsed.year, parsed.month, parsed.day);
      return due.difference(today).inDays;
    }
    return 999;
  }

  String _getDynamicPriority(dynamic task) {
    final String dbPriority = (task['priority'] ?? 'MEDIUM').toString().toUpperCase();
    final String dueDateStr = (task['dueDate'] ?? '').toString();
    final int days = _getDaysRemaining(dueDateStr);
    
    if (days != 999) {
      if (days <= 0) return 'HIGH'; // Today, Yesterday, Overdue -> High Priority
      if (days <= 2) return 'MEDIUM'; // Next 2 days -> Medium Priority
      return 'LOW'; // > 2 days -> Low Priority
    }
    
    return dbPriority; // Fallback to DB priority if date is not parseable
  }

  int _getPriorityValue(dynamic priority) {
    final p = (priority ?? '').toString().toUpperCase();
    if (p == 'HIGH') return 3;
    if (p == 'MEDIUM') return 2;
    if (p == 'LOW') return 1;
    return 0;
  }

  Future<void> _updateStatus(dynamic task, String newStatus) async {
    bool success = false;
    final String taskId = (task['_id'] ?? task['id'] ?? '').toString();
    if (taskId.isEmpty) return;
    
    // Normalize new status strictly for API/Backend compatibility
    final String apiStatus = newStatus.toUpperCase().replaceFirst(' ', '_');

    if (task['isOrder'] == true) {
      try {
        final String type = task['orderType'] == 'RX' ? 'RX' : 'Regular';
        await _orderService.updateOrderStatus(taskId, type, apiStatus);
        success = true;
      } catch (e) {
        success = false;
      }
    } else {
      success = await _taskService.updateTaskStatus(taskId, apiStatus);
    }

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Item moved to $newStatus'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
      }
      _loadTasks();
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayedTasks = _filteredAndSortedTasks;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Operations Center', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 4,
        backgroundColor: const Color(0xFF1A237E),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _loadTasks),
        ],
      ),
      body: Column(
        children: [
          _buildFilterHeader(),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : displayedTasks.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadTasks,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      itemCount: displayedTasks.length,
                      itemBuilder: (context, index) {
                        final task = displayedTasks[index];
                        return _buildPremiumTaskCard(task);
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTaskSheet,
        backgroundColor: const Color(0xFF1A237E),
        label: const Text('CREATE NEW TASK', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.white)),
        icon: const Icon(Icons.add_task, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Status Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatusChip('ALL', 'All Directives'),
                const SizedBox(width: 8),
                _buildStatusChip('PENDING', 'Pending'),
                const SizedBox(width: 8),
                _buildStatusChip('IN_PROGRESS', 'In Progress'),
                const SizedBox(width: 8),
                _buildStatusChip('COMPLETED', 'Completed'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // 2. Sort, Priority and Staff Selectors
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSortSelector(),
                const SizedBox(width: 8),
                _buildPrioritySelector(),
                const SizedBox(width: 8),
                _buildStaffSelector(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String filterKey, String label) {
    final bool isSelected = _selectedStatusFilter == filterKey;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      selected: isSelected,
      onSelected: (val) {
        if (val) {
          setState(() => _selectedStatusFilter = filterKey);
        }
      },
      selectedColor: const Color(0xFF1A237E).withOpacity(0.12),
      checkmarkColor: const Color(0xFF1A237E),
      labelStyle: TextStyle(color: isSelected ? const Color(0xFF1A237E) : Colors.grey[600]),
    );
  }

  Widget _buildSortSelector() {
    return PopupMenuButton<String>(
      onSelected: (val) => setState(() => _sortBy = val),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            const Icon(Icons.sort_rounded, size: 16, color: Color(0xFF1A237E)),
            const SizedBox(width: 6),
            Text(
              _sortByLabel,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1A237E)),
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'DATE_DESC', child: Text('Due Date: Newest First')),
        const PopupMenuItem(value: 'DATE_ASC', child: Text('Due Date: Oldest First')),
        const PopupMenuItem(value: 'PRIORITY_HIGH', child: Text('Priority: High First')),
        const PopupMenuItem(value: 'PRIORITY_LOW', child: Text('Priority: Low First')),
        const PopupMenuItem(value: 'TITLE_AZ', child: Text('Title: A to Z')),
      ],
    );
  }

  Widget _buildPrioritySelector() {
    return PopupMenuButton<String>(
      onSelected: (val) => setState(() => _selectedPriorityFilter = val),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            const Icon(Icons.filter_alt_outlined, size: 16, color: Color(0xFF1A237E)),
            const SizedBox(width: 6),
            Text(
              _selectedPriorityFilter == 'ALL' ? 'Priority: All' : 'Priority: $_selectedPriorityFilter',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1A237E)),
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'ALL', child: Text('Priority: All')),
        const PopupMenuItem(value: 'HIGH', child: Text('High')),
        const PopupMenuItem(value: 'MEDIUM', child: Text('Medium')),
        const PopupMenuItem(value: 'LOW', child: Text('Low')),
      ],
    );
  }

  Widget _buildStaffSelector() {
    String label = 'Staff: All';
    if (_selectedStaffFilter != 'ALL') {
      try {
        final staff = _staffList.firstWhere((s) => s['_id'].toString() == _selectedStaffFilter);
        label = 'Staff: ${staff['name']}';
      } catch (_) {}
    }

    return PopupMenuButton<String>(
      onSelected: (val) => setState(() => _selectedStaffFilter = val),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            const Icon(Icons.people_alt_outlined, size: 16, color: Color(0xFF1A237E)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1A237E)),
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'ALL', child: Text('Staff: All')),
        ..._staffList.map((s) => PopupMenuItem(
          value: s['_id'].toString(),
          child: Text(s['name'] ?? 'Unknown'),
        )),
      ],
    );
  }

  String get _sortByLabel {
    if (_sortBy == 'DATE_ASC') return 'Due Date: Oldest';
    if (_sortBy == 'PRIORITY_HIGH') return 'Priority: High';
    if (_sortBy == 'PRIORITY_LOW') return 'Priority: Low';
    if (_sortBy == 'TITLE_AZ') return 'Title: A-Z';
    return 'Due Date: Newest';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(color: Colors.blue[50], shape: BoxShape.circle),
            child: Icon(Icons.assignment_turned_in_outlined, size: 80, color: Colors.blue[200]),
          ),
          const SizedBox(height: 24),
          const Text('All Clear!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
          const SizedBox(height: 8),
          const Text('No matching directives found today.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildPremiumTaskCard(dynamic task) {
    final String status = (task['status'] ?? 'PENDING').toString().toUpperCase();
    final String title = task['title'] ?? 'Untitled Task';
    final String assignedTo = task['assignedTo'] is Map ? (task['assignedTo']['name'] ?? 'Unassigned') : 'Unassigned';
    final String description = task['description'] ?? '';
    final String priority = _getDynamicPriority(task);
    
    Color accentColor = Colors.orange;
    IconData taskIcon = Icons.task_outlined;
    
    if (task['isOrder'] == true) {
      taskIcon = Icons.shopping_cart_outlined;
      accentColor = const Color(0xFF1A237E); // Professional Indigo
    } else if (title.toLowerCase().contains('call')) {
      taskIcon = Icons.phone_in_talk_outlined;
      accentColor = Colors.blue;
    } else if (title.toLowerCase().contains('repair') || title.toLowerCase().contains('fit')) {
      taskIcon = Icons.build_circle_outlined;
      accentColor = Colors.teal;
    }

    if (status == 'COMPLETED') {
      accentColor = Colors.green;
      taskIcon = Icons.check_circle_outline;
    } else if (status == 'IN_PROGRESS') {
      accentColor = Colors.indigo;
      taskIcon = Icons.pending_actions;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 6, color: accentColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(taskIcon, size: 18, color: accentColor),
                              const SizedBox(width: 8),
                              Text(
                                status.replaceFirst('_', ' '), 
                                style: TextStyle(color: accentColor, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getPriorityColor(priority).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  priority,
                                  style: TextStyle(color: _getPriorityColor(priority), fontWeight: FontWeight.bold, fontSize: 9),
                                ),
                              )
                            ],
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_horiz, color: Colors.grey, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showEditTaskSheet(task);
                              } else if (value == 'delete') {
                                _showDeleteDialog(task);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 18, color: Colors.blue),
                                    SizedBox(width: 8),
                                    Text('Edit Directive', style: TextStyle(fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_forever, size: 18, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete Directive', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(description, style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.4)),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _buildMiniInfo(Icons.account_circle_outlined, assignedTo),
                          const SizedBox(width: 16),
                          _buildMiniInfo(Icons.access_time, task['dueDate'] ?? 'Today'),
                        ],
                      ),
                      const Divider(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (status == 'PENDING')
                            _actionButton('START TASK', Colors.blue, () => _updateStatus(task, 'In Progress')),
                          if (status == 'IN_PROGRESS')
                            _actionButton('MARK COMPLETE', Colors.green, () => _updateStatus(task, 'Completed')),
                          if (status == 'COMPLETED')
                            const Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green, size: 20),
                                SizedBox(width: 6),
                                Text('COMPLETED', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w900, fontSize: 11)),
                              ],
                            ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    if (priority == 'HIGH') return Colors.red;
    if (priority == 'MEDIUM') return Colors.orange;
    return Colors.grey;
  }

  Widget _buildMiniInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _actionButton(String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
      ),
    );
  }

  void _showAddTaskSheet() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String? selectedStaffId;
    List<dynamic> staffList = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20, spreadRadius: 5)],
        ),
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 20),
        child: StatefulBuilder(
          builder: (context, setModalState) {
            if (staffList.isEmpty) {
              _taskService.fetchStaff().then((list) => setModalState(() => staffList = list));
            }

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFF1A237E).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.add_task_rounded, color: Color(0xFF1A237E), size: 24),
                      ),
                      const SizedBox(width: 16),
                      const Text('Create New Directive', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1A237E), letterSpacing: -0.5)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _modalField('TASK TITLE', 'e.g. Call Customer for Pickup', titleController, icon: Icons.title_rounded),
                  const SizedBox(height: 24),
                  _modalField('DETAILED DESCRIPTION', 'Briefly explain what needs to be done', descController, maxLines: 3, icon: Icons.description_outlined),
                  const SizedBox(height: 24),
                  const Text('ASSIGN TO EMPLOYEE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Color(0xFF1A237E), letterSpacing: 1.2)),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.person_pin_rounded, color: Color(0xFF1A237E), size: 20),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      filled: true,
                      fillColor: Colors.grey[50],
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.grey[200]!)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFF1A237E), width: 1.5)),
                    ),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF1A237E)),
                    value: selectedStaffId,
                    items: staffList.map((s) => DropdownMenuItem<String>(value: s['_id'].toString(), child: Text(s['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
                    onChanged: (val) => setModalState(() => selectedStaffId = val),
                    hint: Text('Select Staff Member', style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A237E),
                        foregroundColor: Colors.white,
                        elevation: 8,
                        shadowColor: const Color(0xFF1A237E).withOpacity(0.4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: () async {
                        if (titleController.text.isNotEmpty && selectedStaffId != null) {
                          await _taskService.createTask({
                            'title': titleController.text,
                            'description': descController.text,
                            'assignedTo': selectedStaffId,
                            'status': 'Pending',
                            'priority': 'Medium',
                            'dueDate': 'Today'
                          });
                          if (ctx.mounted) Navigator.pop(ctx);
                          _loadTasks();
                        }
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle_outline_rounded, size: 20),
                          SizedBox(width: 10),
                          Text('ASSIGN DIRECTIVE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showDeleteDialog(dynamic task) {
    final String taskId = (task['_id'] ?? task['id'] ?? '').toString();
    if (taskId.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Task', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text('Are you sure you want to permanently delete this task directive?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final success = await _taskService.deleteTask(taskId);
              if (ctx.mounted) Navigator.pop(ctx);
              if (success) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Task deleted successfully'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
                _loadTasks();
              }
            },
            child: const Text('DELETE', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEditTaskSheet(dynamic task) {
    final String taskId = (task['_id'] ?? task['id'] ?? '').toString();
    if (taskId.isEmpty) return;

    final titleController = TextEditingController(text: task['title'] ?? '');
    final descController = TextEditingController(text: task['description'] ?? '');
    String? selectedStaffId;
    if (task['assignedTo'] is Map) {
      selectedStaffId = (task['assignedTo']['id'] ?? task['assignedTo']['_id'] ?? task['assignedToId'])?.toString();
    }
    List<dynamic> staffList = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20, spreadRadius: 5)],
        ),
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 20),
        child: StatefulBuilder(
          builder: (context, setModalState) {
            if (staffList.isEmpty) {
              _taskService.fetchStaff().then((list) => setModalState(() {
                staffList = list;
                if (selectedStaffId != null && !staffList.any((s) => s['_id'].toString() == selectedStaffId)) {
                  try {
                    final matched = staffList.firstWhere((s) => s['name'] == task['assignedTo']['name']);
                    selectedStaffId = matched['_id'].toString();
                  } catch (_) {}
                }
              }));
            }

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.edit_note_rounded, color: Colors.blue, size: 24),
                      ),
                      const SizedBox(width: 16),
                      const Text('Edit Directive', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1A237E), letterSpacing: -0.5)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _modalField('TASK TITLE', 'e.g. Call Customer for Pickup', titleController, icon: Icons.title_rounded),
                  const SizedBox(height: 24),
                  _modalField('DETAILED DESCRIPTION', 'Briefly explain what needs to be done', descController, maxLines: 3, icon: Icons.description_outlined),
                  const SizedBox(height: 24),
                  const Text('ASSIGN TO EMPLOYEE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Color(0xFF1A237E), letterSpacing: 1.2)),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.person_pin_rounded, color: Color(0xFF1A237E), size: 20),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      filled: true,
                      fillColor: Colors.grey[50],
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.grey[200]!)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFF1A237E), width: 1.5)),
                    ),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF1A237E)),
                    value: selectedStaffId,
                    items: staffList.map((s) => DropdownMenuItem<String>(value: s['_id'].toString(), child: Text(s['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
                    onChanged: (val) => setModalState(() => selectedStaffId = val),
                    hint: Text('Select Staff Member', style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A237E),
                        foregroundColor: Colors.white,
                        elevation: 8,
                        shadowColor: const Color(0xFF1A237E).withOpacity(0.4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: () async {
                        if (titleController.text.isNotEmpty && selectedStaffId != null) {
                          await _taskService.updateTask(taskId, {
                            'title': titleController.text,
                            'description': descController.text,
                            'assignedTo': selectedStaffId,
                            'status': task['status'] ?? 'Pending',
                            'priority': task['priority'] ?? 'Medium',
                            'dueDate': task['dueDate'] ?? 'Today'
                          });
                          if (context.mounted) Navigator.pop(ctx);
                          _loadTasks();
                        }
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.save_rounded, size: 20),
                          SizedBox(width: 10),
                          Text('SAVE CHANGES', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _modalField(String label, String hint, TextEditingController controller, {int maxLines = 1, IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Color(0xFF1A237E), letterSpacing: 1.2)),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
          decoration: InputDecoration(
            prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF1A237E), size: 20) : null,
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14, fontWeight: FontWeight.w500),
            filled: true,
            fillColor: Colors.grey[50],
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.grey[200]!)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFF1A237E), width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          ),
        ),
      ],
    );
  }
}
