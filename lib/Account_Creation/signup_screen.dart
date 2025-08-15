import 'package:flutter/material.dart';
import 'package:safenest/Api_Service/New_api.dart' show ApiService, ApiException;
import 'package:safenest/Account_Creation/auth_form.dart';
import 'package:safenest/Account_Creation/login_screen.dart';

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
  bool _obscurePassword = true;

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService().register(
        fullname: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        role: _selectedRole,
      );

      if (!mounted) return;

      final role = _selectedRole.toLowerCase();
      final roleId = response['roleId']?.toString() ?? '';
      final token = response['token']?.toString() ?? '';

      if (roleId.isEmpty || token.isEmpty) {
        throw ApiException('Registration incomplete - no roleId or token received');
      }

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
          'userId': response['userId'] ?? '',
          'roleId': roleId,
          'token': token,
          'email': _emailController.text.trim(),
          'fullname': _nameController.text.trim(),
        },
      );
    } on ApiException catch (e) {
      setState(() => _errorMessage = _parseError(e));
    } catch (e) {
      setState(() => _errorMessage = 'Registration failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _parseError(ApiException e) {
    if (e.message.contains('400')) return 'Please check your input and try again.';
    if (e.message.contains('409')) return 'This email is already registered.';
    if (e.message.contains('network')) return 'Network error. Please check your connection.';
    return 'Registration error: ${e.message}';
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
      subtitle: 'Create a new account to get started',
      actionText: 'Sign Up',
      isLoading: _isLoading,
      errorMessage: _errorMessage,
      onAction: _handleSignUp,
      alternateActionText: 'Already have an account? Login',
      onAlternateAction: () => Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
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
                controller: _nameController,
                decoration: _inputDecoration('Full Name', Icons.person_outline),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your full name';
                  }
                  if (value.length < 3) {
                    return 'Name must be at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
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
                  if (value.length < 8) {
                    return 'Password must be at least 8 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: _inputDecoration('Role', Icons.people_outline),
                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF5271FF)),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(12),
                items: ['Parent', 'Teacher']
                    .map((role) => DropdownMenuItem(
                          value: role,
                          child: Text(
                            role,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ))
                    .toList(),
                onChanged: _isLoading
                    ? null
                    : (value) => setState(() => _selectedRole = value ?? 'Parent'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select your role';
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