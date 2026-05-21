import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../../../core/utils/auth_snackbar.dart';

class SubscriptionScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const SubscriptionScreen({super.key, required this.userData});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  String _selectedPlan = '1 Year';
  bool _isProcessing = false;
  String? _userName;
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _initRazorpay();
  }

  void _initRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _onPaymentVerified(
      response.orderId ?? '',
      response.paymentId ?? '',
      response.signature ?? '',
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      setState(() => _isProcessing = false);
      AuthSnackBar.show(
        context,
        title: 'Payment Failed',
        message: response.message ?? 'Payment was cancelled or failed.',
        type: AuthSnackBarType.error,
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // Optional external wallet handler
  }

  Future<void> _onPaymentVerified(String orderId, String paymentId, String signature) async {
    try {
      final authService = AuthService();
      final result = await authService.verifyPaymentAndRegister(
        orderId: orderId,
        paymentId: paymentId,
        signature: signature,
        userData: widget.userData,
        subscriptionPlan: _selectedPlan,
      );

      if (mounted) {
        setState(() => _isProcessing = false);
        if (result['success'] == true) {
          _showSuccessDialog();
        } else {
          AuthSnackBar.show(
            context,
            title: 'Registration Failed',
            message: result['message'] ?? 'Unable to complete your registration.',
            type: AuthSnackBarType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        AuthSnackBar.show(
          context,
          title: 'Verification Error',
          message: e.toString(),
          type: AuthSnackBarType.error,
        );
      }
    }
  }

  Future<void> _loadUser() async {
    if (widget.userData.containsKey('name')) {
      setState(() => _userName = widget.userData['name']);
    } else {
      final prefs = await SharedPreferences.getInstance();
      setState(() => _userName = prefs.getString('auth_user_name') ?? 'Admin');
    }
  }

  final List<Map<String, dynamic>> _plans = [
    {
      'title': '1 Month',
      'price': '₹1',
      'subtitle': 'Monthly Plan',
      'icon': Icons.calendar_month_rounded,
      'features': ['Basic Dashboard', '150 Orders/Month', 'Support'],
    },
    {
      'title': '6 Months',
      'price': '₹1',
      'subtitle': 'Half Yearly Plan',
      'icon': Icons.date_range_rounded,
      'features': ['Pro Dashboard', '1500 Orders/Month', 'Priority Support'],
    },
    {
      'title': '1 Year',
      'price': '₹1',
      'subtitle': 'Annual Best Value',
      'icon': Icons.event_available_rounded,
      'features': ['Unlimited Everything', 'Custom Reports', '24/7 Support'],
    },
  ];

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);

    // Extract price cleanly
    final plan = _plans.firstWhere((p) => p['title'] == _selectedPlan);
    final priceString = plan['price'].toString().replaceAll(RegExp(r'[^0-9]'), '');
    final amount = double.tryParse(priceString) ?? 1.0;

    // Detect platform
    final isMobile = !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

    if (!isMobile) {
      // Simulation mode for Desktop & Web
      await Future.delayed(const Duration(seconds: 2));
      if (widget.userData.isNotEmpty) {
        final authService = AuthService();
        final result = await authService.register(
          name: widget.userData['name'] ?? '',
          email: widget.userData['email'] ?? '',
          phone: widget.userData['phone'] ?? '',
          password: widget.userData['password'] ?? '',
          role: widget.userData['role'] ?? 'OWNER',
        );

        if (mounted) {
          setState(() => _isProcessing = false);
          if (result['success'] == true) {
            _showSuccessDialog();
          } else {
            AuthSnackBar.show(
              context,
              title: 'Registration Failed (Simulated)',
              message: result['message'] ?? 'Unable to create your account.',
              type: AuthSnackBarType.error,
            );
          }
        }
      } else {
        if (mounted) {
          setState(() => _isProcessing = false);
          _showSuccessDialog();
        }
      }
      return;
    }

    // Real Razorpay integration for Mobile
    try {
      final authService = AuthService();
      final orderResult = await authService.createRazorpayOrder(amount: amount);

      if (orderResult['success'] == true) {
        final orderId = orderResult['id']?.toString() ?? '';
        final keyId = orderResult['keyId']?.toString() ?? 'rzp_live_SoqYaLiOI6KmXVV';
        final amountInPaise = orderResult['amount'] as int? ?? (amount * 100).toInt();

        var options = {
          'key': keyId,
          'amount': amountInPaise,
          'name': 'Retail Lens',
          'order_id': orderId,
          'description': 'Subscription Plan - $_selectedPlan',
          'prefill': {
            'contact': widget.userData['phone'] ?? '',
            'email': widget.userData['email'] ?? '',
          }
        };

        _razorpay.open(options);
      } else {
        if (mounted) {
          setState(() => _isProcessing = false);
          AuthSnackBar.show(
            context,
            title: 'Order Creation Failed',
            message: orderResult['message'] ?? 'Could not create payment order.',
            type: AuthSnackBarType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        AuthSnackBar.show(
          context,
          title: 'Payment Initialization Error',
          message: e.toString(),
          type: AuthSnackBarType.error,
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 64),
            ),
            const SizedBox(height: 24),
            const Text(
              'Payment Successful!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Your subscription to the $_selectedPlan plan is now active.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 15),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false); // Back to login
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('GO TO LOGIN', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Select Subscription', style: TextStyle(fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: widget.userData.isNotEmpty, // Only show back if registering
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              color: Colors.white,
              child: Column(
                children: [
                  const Text(
                    'Choose Your Plan',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select a subscription plan for $_userName',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: _plans.map((plan) => _buildPlanCard(plan)).toList(),
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.security_rounded, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        'Secure checkout with 256-bit SSL encryption',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _processPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: _isProcessing
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'PAY FOR $_selectedPlan'.toUpperCase(),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    bool isSelected = _selectedPlan == plan['title'];
    
    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = plan['title']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF2563EB).withValues(alpha: 0.1) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    plan['icon'],
                    color: isSelected ? const Color(0xFF2563EB) : Colors.grey[600],
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan['title'],
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        plan['subtitle'],
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Text(
                  plan['price'],
                  style: TextStyle(
                    fontSize: 22, 
                    fontWeight: FontWeight.bold, 
                    color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF1E293B)
                  ),
                ),
              ],
            ),
            if (isSelected) ...[
              const Divider(height: 32),
              ...List.generate(plan['features'].length, (index) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
                    const SizedBox(width: 12),
                    Text(
                      plan['features'][index],
                      style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
                    ),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }
}
