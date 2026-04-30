import 'package:flutter/material.dart';
import '../services/task_service.dart';
import 'package:intl/intl.dart';
import '../../orders/services/order_service.dart';

class TaskManagementScreen extends StatefulWidget {
  const TaskManagementScreen({super.key});

  @override
  State<TaskManagementScreen> createState() => _TaskManagementScreenState();
}

class _TaskManagementScreenState extends State<TaskManagementScreen> {
  final TaskService _taskService = TaskService();
  final OrderService _orderService = OrderService();
  List<dynamic> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    try {
      final tasks = await _taskService.fetchTasks();
      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(dynamic task, String newStatus) async {
    bool success = false;
    final String taskId = (task['_id'] ?? task['id'] ?? '').toString();
    if (taskId.isEmpty) return;
    
    if (task['isOrder'] == true) {
      try {
        final String type = task['orderType'] == 'RX' ? 'RX' : 'Regular';
        await _orderService.updateOrderStatus(taskId, type, newStatus);
        success = true;
      } catch (e) {
        success = false;
      }
    } else {
      success = await _taskService.updateTaskStatus(taskId, newStatus);
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
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _tasks.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadTasks,
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _tasks.length,
                itemBuilder: (context, index) {
                  final task = _tasks[index];
                  return _buildPremiumTaskCard(task);
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTaskSheet,
        backgroundColor: const Color(0xFF1A237E),
        label: const Text('CREATE NEW TASK', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.white)),
        icon: const Icon(Icons.add_task, color: Colors.white),
      ),
    );
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
          const Text('No pending tasks for your team today.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildPremiumTaskCard(dynamic task) {
    final String status = task['status'] ?? 'Pending';
    final String title = task['title'] ?? 'Untitled Task';
    final String assignedTo = task['assignedTo'] is Map ? (task['assignedTo']['name'] ?? 'Unassigned') : 'Unassigned';
    final String description = task['description'] ?? '';
    
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
    } else if (status == 'Completed') {
      accentColor = Colors.green;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))
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
                              Text(status.toUpperCase(), style: TextStyle(color: accentColor, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
                            ],
                          ),
                          const Icon(Icons.more_horiz, color: Colors.grey, size: 20),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(description, style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.4)),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _buildMiniInfo(Icons.account_circle_outlined, assignedTo),
                          const SizedBox(width: 16),
                          _buildMiniInfo(Icons.access_time, 'Today'),
                        ],
                      ),
                      const Divider(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (status == 'Pending')
                            _actionButton('START TASK', Colors.blue, () => _updateStatus(task, 'In Progress')),
                          if (status == 'In Progress')
                            _actionButton('MARK COMPLETE', Colors.green, () => _updateStatus(task, 'Completed')),
                          if (status == 'Completed')
                            const Icon(Icons.check_circle, color: Colors.green, size: 28),
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
                          if (context.mounted) Navigator.pop(ctx);
                          _loadTasks();
                        }
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bolt_rounded, size: 20),
                          SizedBox(width: 10),
                          Text('ASSIGN TASK NOW', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 14)),
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
