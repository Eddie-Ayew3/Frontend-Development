import 'package:flutter/material.dart';
import 'package:safenest/accounts/auth_form.dart';
import 'package:safenest/accounts/signup_screen.dart';
import 'package:safenest/api/New_api.dart';

/// Login screen that allows users to authenticate with email and password.
/// Features:
/// - Email validation
/// - Password validation (min 6 chars)
/// - Password visibility toggle
/// - Forgot password option
/// - Link to registration screen
/// - Error handling with user-friendly messages
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
  bool _obscurePassword = true;

  /// Handles the login process by:
  /// 1. Validating the form
  /// 2. Calling the API service
  /// 3. Handling success/error cases
  /// 4. Navigating to appropriate dashboard based on user role
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

      // Navigate with slide transition
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
      setState(() => _errorMessage = 'An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Converts API exception messages to user-friendly error messages
  String _parseLoginError(ApiException e) {
    if (e.message.contains('401')) return 'Invalid email or password. Please try again.';
    if (e.message.contains('network')) return 'Network error. Please check your connection.';
    if (e.message.contains('timeout')) return 'Request timed out. Please try again.';
    return 'Login failed: ${e.message}';
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
      onAlternateAction: () => Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const SignUpScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      ),
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
              // Email field
              TextFormField(
                controller: _emailController,
                decoration: _inputDecoration('Email', Icons.email_outlined),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Password field with visibility toggle
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
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
              // Forgot password link
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          // TODO: Implement forgot password functionality
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Forgot password feature coming soon!'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
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

  /// Creates a consistent input decoration for form fields
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