import 'package:flutter/material.dart';
import 'package:safenest/accounts/auth_form.dart';
import 'package:safenest/api/New_api.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true; // Add this line

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;
      
      final role = response['role']?.toString().toLowerCase() ?? '';
      final roleId = response['roleId']?.toString() ?? '';
      final token = response['token']?.toString() ?? '';

      if (role.isEmpty || roleId.isEmpty || token.isEmpty) {
        throw ApiException('Invalid login response data');
      }

      final dashboardRoutes = {
        'parent': '/parent_dashboard',
        'teacher': '/teacher_dashboard',
        'admin': '/admin_dashboard',
      };

      if (!dashboardRoutes.containsKey(role)) {
        throw ApiException('Unauthorized role: $role');
      }

      Navigator.pushReplacementNamed(
        context,
        dashboardRoutes[role]!,
        arguments: {
          'role': role,
          'roleId': roleId,
          'token': token,
          'email': response['email'] ?? '',
          'fullname': response['fullname'] ?? '',
        },
      );

    } on ApiException catch (e) {
      setState(() => _errorMessage = _parseLoginError(e));
    } catch (e) {
      setState(() => _errorMessage = 'An unexpected error occurred');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _parseLoginError(ApiException e) {
    if (e.message.contains('401')) return 'Invalid email or password';
    if (e.message.contains('network')) return 'Network error occurred';
    return e.message;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthForm(
      title: 'SafeNest',
      subtitle: 'Welcome back! Please login to your account',
      actionText: 'Login',
      isLoading: _isLoading,
      errorMessage: _errorMessage,
      onAction: _handleLogin,
      alternateActionText: 'Don\'t have an account? Sign Up',
      onAlternateAction: () => Navigator.pushNamed(context, '/register'),
      logo: Image.asset(
        'assets/safenest.png',
        height: 80,
        width: 80,
        fit: BoxFit.contain,
      ),
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: _inputDecoration('Email', Icons.email_outlined),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword, // Use the state variable here
                decoration: _inputDecoration('Password', Icons.lock_outline).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: const Color(0xFF5271FF),
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // Add forgot password functionality
                  },
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: Color(0xFF5271FF),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF5271FF)),
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF5271FF), width: 1.5),
      ),
    );
  }
}