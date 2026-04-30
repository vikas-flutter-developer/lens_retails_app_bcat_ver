import 'package:flutter/material.dart';
import 'subscription_screen.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;

  void _navigateToSubscription() {
    if (_formKey.currentState!.validate()) {
      final userData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'shopName': _shopNameController.text.trim(),
        'address': _addressController.text.trim(),
        'password': _passwordController.text,
      };
      
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SubscriptionScreen(userData: userData),
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _shopNameController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('New Registration', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Retailer Registration',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your business details to create a new account.',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),
              
              _buildSectionTitle('PERSONAL DETAILS'),
              _buildTextField('Full Name', _nameController, Icons.person_outline),
              const SizedBox(height: 16),
              _buildTextField('Email Address', _emailController, Icons.email_outlined),
              const SizedBox(height: 16),
              _buildTextField('Phone / Mobile', _phoneController, Icons.phone_android_outlined, isPhone: true),
              
              const SizedBox(height: 32),
              _buildSectionTitle('BUSINESS DETAILS'),
              _buildTextField('Shop/Business Name', _shopNameController, Icons.storefront_outlined),
              const SizedBox(height: 16),
              _buildTextField('Business Address', _addressController, Icons.location_on_outlined, maxLines: 2),
              
              const SizedBox(height: 32),
              _buildSectionTitle('SECURITY'),
              _buildTextField('Password', _passwordController, Icons.lock_outline, isPassword: true),
              const SizedBox(height: 16),
              _buildTextField('Confirm Password', _confirmPasswordController, Icons.check_circle_outline, isPassword: true),
              
              const SizedBox(height: 40),
              SizedBox(
                height: 60,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _navigateToSubscription,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('CONTINUE TO SUBSCRIPTION', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      SizedBox(width: 12),
                      Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.blue[800],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isPassword = false, bool isPhone = false, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please enter $label';
        if (isPassword && value.length < 6) return 'Password too short';
        if (label == 'Confirm Password' && value != _passwordController.text) return 'Passwords do not match';
        return null;
      },
    );
  }
}

