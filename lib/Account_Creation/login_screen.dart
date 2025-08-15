// Modified login_screen.dart
// Changes:
// - Added platform detection imports
// - In _handleLogin, after successful API login:
//   - If on mobile (!kIsWeb) and role == 'admin', show error and don't navigate
//   - If on web (kIsWeb) and role != 'admin', show error and don't navigate
//   - Otherwise, proceed with navigation
// - Added constant for web URL (modifiable)
// - Added constant for allowed mobile roles (modifiable)

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:safenest/Account_Creation/auth_form.dart';
import 'package:safenest/Account_Creation/signup_screen.dart';
import 'package:safenest/Api_Service/New_api.dart';


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

  // Modifiable: Web dashboard URL for admin error message
  static const String adminWebUrl = 'https://admin.mydomain.com';

  // Modifiable: List of roles allowed on mobile platforms
  static const List<String> mobileAllowedRoles = ['parent', 'teacher'];

  // Modifiable: Role required for web access
  static const String webRequiredRole = 'admin';

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService().login(
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

      // Role restriction checks
      if (!kIsWeb && role == webRequiredRole) {
        // Block admin on mobile
        throw ApiException('Admins are restricted on mobile. Please use the web dashboard at $adminWebUrl');
      }

      if (kIsWeb && role != webRequiredRole) {
        // Block non-admin on web (ensures web app is admin-only)
        throw ApiException('This web app is for admins only. Please use the mobile app for $role access.');
      }

      if (!kIsWeb && !mobileAllowedRoles.contains(role)) {
        // General mobile role check (in case of new roles)
        throw ApiException('Unauthorized role for mobile: $role');
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
          'userId': response['userId'] ?? '',
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

  String _parseLoginError(ApiException e) {
    if (e.message.contains('401')) return 'Invalid email or password. Please try again.';
    if (e.message.contains('network')) return 'Network error. Please check your connection.';
    if (e.message.contains('timeout')) return 'Request timed out. Please try again.';
    // Preserve custom error messages from role checks
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
    // Existing build method remains unchanged
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
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
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