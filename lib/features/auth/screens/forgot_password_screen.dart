import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'reset_password_screen.dart';
import '../../../core/utils/auth_snackbar.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final result = await _authService.forgotPassword(_emailController.text.trim());

      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;

      if (result['success'] == true) {
        final resetToken = result['resetToken']?.toString() ?? '';
        
        if (resetToken.isEmpty) {
          AuthSnackBar.show(
            context,
            title: 'Request Failed',
            message: 'This email address is not registered with us. Please check your spelling.',
            type: AuthSnackBarType.error,
          );
          return;
        }
        
        AuthSnackBar.show(
          context,
          title: 'Token Generated',
          message: 'Security token has been sent successfully.',
          type: AuthSnackBarType.success,
        );

        // Transition to ResetPasswordScreen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ResetPasswordScreen(
              email: _emailController.text.trim(),
              token: resetToken,
            ),
          ),
        );
      } else {
        AuthSnackBar.show(
          context,
          title: 'Request Failed',
          message: result['message'] ?? 'Unable to find an account with that email ID.',
          type: AuthSnackBarType.error,
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Forgot Password',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon Header
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock_reset_rounded,
                          color: Color(0xFF2563EB),
                          size: 64,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    const Text(
                      'Reset your password',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Enter your registered email ID below. We will send a security token to reset your password.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Email Input
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Email ID',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'Enter your email ID',
                            hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                            prefixIcon: const Icon(Icons.mail_outline, color: Color(0xFF9CA3AF), size: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your email ID';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Reset Button
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor: const Color(0xFF93C5FD),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.send_rounded, size: 20),
                                  SizedBox(width: 10),
                                  Text(
                                    'Reset Your Password',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
