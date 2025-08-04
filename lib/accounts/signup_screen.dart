import 'package:flutter/material.dart';
import 'package:safenest/accounts/auth_form.dart';
import 'package:safenest/api/New_api.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'Parent';
  bool _isLoading = false;
  String? _errorMessage;



Future<void> _handleSignUp() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  try {
    final response = await ApiService.register(
      fullname: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      role: _selectedRole,
    );

    if (!mounted) return;
    
    final role = _selectedRole.toLowerCase();
    final roleId = response['roleId']?.toString() ?? '';

    if (roleId.isEmpty) {
      throw ApiException('Registration incomplete - no roleId received');
    }

    // Define allowed roles and their dashboards
    const allowedRoles = {
      'parent': '/parent_dashboard',
      'teacher': '/teacher_dashboard',
    };

    if (!allowedRoles.containsKey(role)) {
      throw ApiException('Unauthorized role: $role');
    }

    Navigator.pushReplacementNamed(
      context,
      allowedRoles[role]!,
      arguments: {
        'role': role,
        'roleId': roleId,
        'email': _emailController.text.trim(),
        'fullname': _nameController.text.trim(),
      },
    );

  } on ApiException catch (e) {
    setState(() => _errorMessage = _parseError(e));
  } catch (e) {
    setState(() => _errorMessage = 'An unexpected error occurred');
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

  String _parseError(ApiException e) {
    if (e.message.contains('400')) return 'Invalid input data';
    if (e.message.contains('409')) return 'Email already registered';
    return e.message;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthForm(
      title: 'SafeNest',
      subtitle: 'Create a new account',
      actionText: 'Sign Up',
      isLoading: _isLoading,
      errorMessage: _errorMessage,
      onAction: _handleSignUp,
      alternateActionText: 'Already have an account? Login',
      onAlternateAction: () => Navigator.pushNamed(context, '/login'),
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration('Full Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
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
                  if (value.length < 8) {
                    return 'Password must be at least 8 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: _inputDecoration('Role'),
                items: ['Parent', 'Teacher']
                    .map((role) => DropdownMenuItem(
                          value: role,
                          child: Text(role),
                        ))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedRole = value ?? 'Parent'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a role';
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