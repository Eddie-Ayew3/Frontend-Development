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

    // Define dashboard routes with arguments
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
      subtitle: 'Login to your account',
      actionText: 'Login',
      isLoading: _isLoading,
      errorMessage: _errorMessage,
      onAction: _handleLogin,
      alternateActionText: 'Don\'t have an account? Sign Up',
      onAlternateAction: () => Navigator.pushNamed(context, '/register'),
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: _inputDecoration('Email'),
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: _inputDecoration('Password'),
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
            ],
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF0F0F0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}