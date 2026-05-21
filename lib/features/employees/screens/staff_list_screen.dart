import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/staff_service.dart';
import '../../tasks/screens/task_management_screen.dart';

class StaffListScreen extends StatefulWidget {
  const StaffListScreen({super.key});

  @override
  State<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends State<StaffListScreen> {
  final StaffService _staffService = StaffService();
  List<Map<String, dynamic>> _staff = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    setState(() => _isLoading = true);
    try {
      final list = await _staffService.fetchStaff();
      setState(() {
        _staff = list.map((item) {
          if (item is Map) {
            return Map<String, dynamic>.from(item);
          }
          return <String, dynamic>{};
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading staff: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showAddStaffSheet() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController roleController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    String status = 'Active';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20, spreadRadius: 5)],
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
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const Row(
                children: [
                  Icon(Icons.person_add_rounded, color: Color(0xFF1A237E), size: 24),
                  SizedBox(width: 12),
                  Text('Register Staff Member', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: roleController,
                decoration: InputDecoration(
                  labelText: 'Job Role / Designation',
                  hintText: 'e.g. Optometrist, Sales Executive',
                  prefixIcon: const Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () async {
                    if (nameController.text.isNotEmpty && roleController.text.isNotEmpty) {
                      final success = await _staffService.createStaff({
                        'name': nameController.text,
                        'role': roleController.text,
                        'phone': phoneController.text,
                        'status': status,
                      });
                      if (success) {
                        _loadStaff();
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Staff Member Registered!'), behavior: SnackBarBehavior.floating),
                          );
                        }
                      }
                    }
                  },
                  child: const Text('Register Staff', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditStaffSheet(Map<String, dynamic> member) {
    final String staffId = (member['_id'] ?? member['id'] ?? '').toString();
    if (staffId.isEmpty) return;

    final TextEditingController nameController = TextEditingController(text: member['name']);
    final TextEditingController roleController = TextEditingController(text: member['role']);
    final TextEditingController phoneController = TextEditingController(text: member['phone']);
    String selectedStatus = member['status'] ?? 'Active';

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
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20, spreadRadius: 5)],
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
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const Row(
                  children: [
                    Icon(Icons.edit_note_rounded, color: Colors.blue, size: 24),
                    SizedBox(width: 12),
                    Text('Edit Staff Details', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
                  ],
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: roleController,
                  decoration: InputDecoration(
                    labelText: 'Job Role / Designation',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 20),
                const Text('EMPLOYMENT STATUS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF1A237E), letterSpacing: 0.5)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Active', style: TextStyle(fontWeight: FontWeight.bold)),
                      selected: selectedStatus == 'Active',
                      onSelected: (val) {
                        if (val) setModalState(() => selectedStatus = 'Active');
                      },
                      selectedColor: Colors.green[100],
                      checkmarkColor: Colors.green[800],
                      labelStyle: TextStyle(color: selectedStatus == 'Active' ? Colors.green[800] : Colors.grey),
                    ),
                    const SizedBox(width: 12),
                    ChoiceChip(
                      label: const Text('Inactive', style: TextStyle(fontWeight: FontWeight.bold)),
                      selected: selectedStatus == 'Inactive',
                      onSelected: (val) {
                        if (val) setModalState(() => selectedStatus = 'Inactive');
                      },
                      selectedColor: Colors.orange[100],
                      checkmarkColor: Colors.orange[800],
                      labelStyle: TextStyle(color: selectedStatus == 'Inactive' ? Colors.orange[800] : Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A237E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () async {
                      if (nameController.text.isNotEmpty && roleController.text.isNotEmpty) {
                        final success = await _staffService.updateStaff(staffId, {
                          'name': nameController.text,
                          'role': roleController.text,
                          'phone': phoneController.text,
                          'status': selectedStatus,
                        });
                        if (success) {
                          _loadStaff();
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Staff record updated!'), behavior: SnackBarBehavior.floating),
                            );
                          }
                        }
                      }
                    },
                    child: const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> member) {
    final String staffId = (member['_id'] ?? member['id'] ?? '').toString();
    if (staffId.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Staff?'),
          ],
        ),
        content: Text('Are you sure you want to remove ${member['name']} from the store records?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final success = await _staffService.deleteStaff(staffId);
              if (ctx.mounted) Navigator.pop(ctx);
              if (success) {
                _loadStaff();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Staff record deleted'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
                  );
                }
              }
            },
            child: const Text('DELETE', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showStaffDetailSheet(Map<String, dynamic> staff) {
    final String staffId = (staff['_id'] ?? staff['id'] ?? '').toString();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            CircleAvatar(
              radius: 40,
              backgroundColor: const Color(0xFF1A237E),
              child: Text(staff['name'][0], style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            Text(staff['name'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
            Text(staff['role'], style: TextStyle(fontSize: 16, color: Colors.grey.shade600, letterSpacing: 0.5)),
            const SizedBox(height: 20),

            // Async Task Counts
            if (staffId.isNotEmpty)
              FutureBuilder<Map<String, dynamic>?>(
                future: _staffService.fetchTaskCounts(staffId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A237E)),
                      ),
                    );
                  }
                  final counts = snapshot.data;
                  if (counts == null) return const SizedBox();
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildCountItem('Assigned', counts['assigned'] ?? 0, Colors.blue),
                        _buildCountItem('Pending', counts['pending'] ?? 0, Colors.orange),
                        _buildCountItem('Completed', counts['completed'] ?? 0, Colors.green),
                      ],
                    ),
                  );
                },
              ),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final Uri url = Uri.parse('tel:${staff['phone']}');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      }
                    },
                    icon: const Icon(Icons.phone_in_talk_outlined),
                    label: const Text('Call Staff'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFF1A237E)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      foregroundColor: const Color(0xFF1A237E),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF1A237E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCountItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(count.toString(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Store Staff', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 4,
        backgroundColor: const Color(0xFF1A237E),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadStaff,
          ),
          IconButton(
            icon: const Icon(Icons.person_add, color: Colors.white),
            onPressed: _showAddStaffSheet,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _staff.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadStaff,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _staff.length,
                    itemBuilder: (context, index) {
                      final s = _staff[index];
                      final isActive = s['status'] == 'Active';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shadowColor: Colors.black12,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: CircleAvatar(
                            radius: 25,
                            backgroundColor: const Color(0xFF1A237E),
                            child: Text(s['name'] != null && s['name'].isNotEmpty ? s['name'][0] : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                          title: Text(s['name'] ?? 'No Name', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text('${s['role'] ?? 'Staff'}\n${s['phone'] ?? ''}', style: TextStyle(color: Colors.grey.shade600, height: 1.3)),
                          ),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
                                onPressed: () => _showEditStaffSheet(s),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                onPressed: () => _confirmDelete(s),
                              ),
                              IconButton(
                                icon: const Icon(Icons.task_outlined, color: Color(0xFF1A237E)),
                                onPressed: () {
                                  final String staffId = (s['_id'] ?? s['id'] ?? '').toString();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => TaskManagementScreen(initialStaffId: staffId),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.circle, size: 10, color: isActive ? Colors.green : Colors.orange),
                                  const SizedBox(height: 4),
                                  Text(s['status'] ?? 'Active', style: TextStyle(color: isActive ? Colors.green : Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                          onTap: () => _showStaffDetailSheet(s),
                        ),
                      );
                    },
                  ),
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
            child: Icon(Icons.people_outline_rounded, size: 80, color: Colors.blue[200]),
          ),
          const SizedBox(height: 24),
          const Text('No Staff Registered', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
          const SizedBox(height: 8),
          const Text('Add staff members to begin managing your store.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
