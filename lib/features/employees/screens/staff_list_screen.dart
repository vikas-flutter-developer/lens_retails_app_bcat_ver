import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../tasks/screens/task_management_screen.dart';

class StaffListScreen extends StatefulWidget {
  const StaffListScreen({super.key});

  @override
  State<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends State<StaffListScreen> {
  static const String _staffKey = 'store_staff_persistence';
  
  List<Map<String, dynamic>> _staff = [
    {'_id': 'S1', 'name': 'Rahul Verma', 'role': 'Sales / Optometrist', 'phone': '9876543210', 'status': 'Active'},
    {'_id': 'S2', 'name': 'Priya Singh', 'role': 'Store Manager', 'phone': '9123456780', 'status': 'Active'},
    {'_id': 'S3', 'name': 'Amit Kumar', 'role': 'Technician (Lab)', 'phone': '9988776655', 'status': 'Active'},
  ];

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedData = prefs.getString(_staffKey);
    if (savedData != null) {
      try {
        final List<dynamic> decoded = jsonDecode(savedData);
        setState(() {
          _staff = List<Map<String, dynamic>>.from(decoded);
        });
      } catch (e) {
        debugPrint('❌ [StaffList] Error loading staff: $e');
      }
    }
  }

  Future<void> _saveStaff() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_staffKey, jsonEncode(_staff));
    debugPrint('💾 [StaffList] Staff saved locally');
  }

  void _showAddStaffSheet() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController roleController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
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
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const Text('Add New Staff Member', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
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
                      setState(() {
                        _staff.insert(0, {
                          '_id': DateTime.now().millisecondsSinceEpoch.toString(),
                          'name': nameController.text,
                          'role': roleController.text,
                          'phone': phoneController.text,
                          'status': 'Active',
                        });
                      });
                      await _saveStaff();
                      if (!mounted) return;
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Staff Member Added!')));
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

  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Staff?'),
        content: Text('Are you sure you want to remove ${_staff[index]['name']} from the store records?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          TextButton(
            onPressed: () async {
              setState(() {
                _staff.removeAt(index);
              });
              await _saveStaff();
              if (!mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Staff record deleted')));
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showStaffDetailSheet(Map<String, dynamic> staff) {
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
            const SizedBox(height: 32),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Staff'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _showAddStaffSheet,
          )
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _staff.length,
        itemBuilder: (context, index) {
          final s = _staff[index];
          final isActive = s['status'] == 'Active';
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: CircleAvatar(
                radius: 25,
                backgroundColor: const Color(0xFF1A237E),
                child: Text(s['name'][0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              title: Text(s['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text('${s['role']}\n${s['phone']}', style: TextStyle(color: Colors.grey.shade600, height: 1.3)),
              ),
              isThreeLine: true,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => _confirmDelete(index),
                  ),
                  IconButton(
                    icon: const Icon(Icons.task_outlined, color: Color(0xFF1A237E)),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const TaskManagementScreen()));
                    },
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.circle, size: 12, color: isActive ? Colors.green : Colors.orange),
                      const SizedBox(height: 4),
                      Text(s['status'], style: TextStyle(color: isActive ? Colors.green : Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              onTap: () => _showStaffDetailSheet(s),
            ),
          );
        },
      ),
    );
  }
}
