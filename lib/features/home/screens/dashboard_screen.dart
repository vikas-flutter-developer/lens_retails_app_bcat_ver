import 'package:flutter/material.dart';
import '../../orders/screens/add_order_screen.dart';
import '../../orders/screens/my_order_list_screen.dart';
import '../../ledger/screens/my_ledger_screen.dart';
import '../../auth/services/auth_service.dart';

import 'home_dashboard_tab.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  final AuthService _authService = AuthService();
  // Used to signal HomeDashboardTab to reload its data
  final ValueNotifier<int> _reloadSignal = ValueNotifier<int>(0);

  late List<Widget> _screens;
  
  @override
  void initState() {
    super.initState();
    // Screens are dynamically generated in build() using UniqueKey for some, but HomeDashboardTab uses a Listenable
  }

  List<Widget> _buildScreens() {
    return [
       HomeDashboardTab(
         reloadSignal: _reloadSignal, 
         onProfileTap: _showProfileDialog,
         onAddOrder: () {
           setState(() {
             _currentIndex = 1;
           });
         }
       ),
       AddOrderScreen(
         onBack: () {
           setState(() {
             _currentIndex = 0;
           });
         },
       ),
       // Force remount MyOrderListScreen when navigated to so it fetches latest status
       MyOrderListScreen(key: UniqueKey()),
       const MyLedgerScreen(),
    ];
  }

  void _showProfileDialog() async {
    final name = await _authService.getUserName();
    final id = await _authService.getUserId() ?? 'Unknown';
    final details = await _authService.getUserDetails();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => _ProfileDialogContent(
        name: name,
        id: id,
        details: details,
        authService: _authService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: IndexedStack(
        index: _currentIndex,
        children: _buildScreens(),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
        ),
        child: NavigationBar(
          backgroundColor: Colors.white,
          elevation: 0,
          height: 65,
          indicatorColor: Colors.blue.withOpacity(0.1),
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
            if (index == 0) _reloadSignal.value++;
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, color: Color(0xFF64748B)),
              selectedIcon: Icon(Icons.home, color: Colors.blue),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.add_circle_outline, color: Color(0xFF64748B)),
              selectedIcon: Icon(Icons.add_circle, color: Colors.blue),
              label: 'New Order',
            ),
            NavigationDestination(
              icon: Icon(Icons.assignment_outlined, color: Color(0xFF64748B)),
              selectedIcon: Icon(Icons.assignment, color: Colors.blue),
              label: 'Orders',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF64748B)),
              selectedIcon: Icon(Icons.account_balance_wallet, color: Colors.blue),
              label: 'Ledger',
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileDialogContent extends StatefulWidget {
  final String name;
  final String id;
  final Map<String, String?> details;
  final AuthService authService;

  const _ProfileDialogContent({
    required this.name, 
    required this.id, 
    required this.details,
    required this.authService
  });

  @override
  State<_ProfileDialogContent> createState() => _ProfileDialogContentState();
}

class _ProfileDialogContentState extends State<_ProfileDialogContent> {
  bool _isEditing = false;
  bool _isSaving = false;
  
  late TextEditingController _gstinController;
  late TextEditingController _cardController;
  late TextEditingController _addressController;
  late TextEditingController _stateController;
  late TextEditingController _pincodeController;

  @override
  void initState() {
    super.initState();
    _gstinController = TextEditingController(text: widget.details['gstin']);
    _cardController = TextEditingController(text: widget.details['cardNumber']);
    _addressController = TextEditingController(text: widget.details['address']);
    _stateController = TextEditingController(text: widget.details['state'] ?? 'Maharashtra');
    _pincodeController = TextEditingController(text: widget.details['pincode']);
  }

  @override
  void dispose() {
    _gstinController.dispose();
    _cardController.dispose();
    _addressController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    
    final updates = {
      'gstin': _gstinController.text,
      'cardNumber': _cardController.text,
      'address': _addressController.text,
      'state': _stateController.text,
      'pincode': _pincodeController.text,
    };
    
    final result = await widget.authService.updateRetailerProfile(updates);
    
    if (mounted) {
       setState(() => _isSaving = false);
       if (result['success'] == true) {
          Navigator.pop(context); // Close dialog to refresh or show success
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile Updated Successfully'), backgroundColor: Colors.green));
           // Ideally we should refresh the parent dashboard but simplistic approach is fine.
       } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Update Failed'), backgroundColor: Colors.red));
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Premium Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Retailer Profile',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              widget.id,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (!_isEditing)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: IconButton(
                        icon: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 28),
                        onPressed: () => setState(() => _isEditing = true),
                        tooltip: 'Edit Profile',
                      ),
                    ),
                ],
              ),
            ),

            // Content Area
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_isEditing) ...[
                      _buildDisplayCard(Icons.person_outline_rounded, 'Retailer Name', widget.name),
                      const SizedBox(height: 16),
                      _buildDisplayCard(Icons.qr_code_rounded, 'GSTIN Number', _gstinController.text.isEmpty ? 'Not Registered' : _gstinController.text),
                      const SizedBox(height: 16),
                      _buildDisplayCard(Icons.card_membership_rounded, 'Business Card', _cardController.text.isEmpty ? 'Not Linked' : _cardController.text),
                      const SizedBox(height: 16),
                      _buildDisplayCard(
                        Icons.location_on_outlined, 
                        'Business Address', 
                        (_addressController.text.isNotEmpty || _stateController.text.isNotEmpty)
                          ? '${_addressController.text}\n${_stateController.text} - ${_pincodeController.text}'.trim()
                          : 'No Address Set',
                        isMultiLine: true,
                      ),
                    ] else ...[
                      const Text('Update Business Details', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 13)),
                      const SizedBox(height: 16),
                      _buildEditField('GSTIN Number', _gstinController, icon: Icons.qr_code),
                      const SizedBox(height: 16),
                      _buildEditField('Card Number', _cardController, icon: Icons.credit_card),
                      const SizedBox(height: 16),
                      _buildEditField('Store Address', _addressController, maxLines: 2, icon: Icons.map),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildEditField('State', _stateController)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildEditField('Pincode', _pincodeController, isNumber: true)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Action Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Row(
                children: [
                  if (_isEditing) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _isEditing = false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: _isSaving 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                          : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ] else ...[
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[600],
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                      child: const Text('Close'),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await widget.authService.logout();
                        if (context.mounted) {
                          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                        }
                      },
                      icon: const Icon(Icons.logout_rounded, size: 20),
                      label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[50],
                        foregroundColor: Colors.red[700],
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisplayCard(IconData icon, String label, String value, {bool isMultiLine = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Row(
        crossAxisAlignment: isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Icon(icon, color: Colors.blue[700], size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[500],
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEditField(String label, TextEditingController controller, {int maxLines = 1, bool isNumber = false, IconData? icon}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, size: 20) : null,
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }
}


