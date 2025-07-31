import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:safenest/api_services/file.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.safeApiCall(() => ApiService.login(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          ));

      final role = response['role'] as String?;
      final userId = response['userId']?.toString();
      if (role == null || role.isEmpty) {
        throw ApiException('Invalid user role');
      }
      if (userId == null || userId.isEmpty) {
        throw ApiException('User ID is missing in response');
      }

      await ApiService.setAuthToken(response['token']);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login successful!')),
      );

      final route = _getDashboardRouteForRole(role);
      if (await Navigator.pushReplacementNamed(context, route, arguments: userId) == null) {
        setState(() => _errorMessage = 'Invalid navigation route');
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _errorMessage = _mapErrorToMessage(e));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: ${_mapErrorToMessage(e)}'),
            action: e.message == 'Network error'
                ? SnackBarAction(
                    label: 'Retry',
                    onPressed: _handleLogin,
                  )
                : null,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'An unexpected error occurred');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('An unexpected error occurred'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _handleLogin,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _mapErrorToMessage(ApiException e) {
    switch (e.message) {
      case 'Invalid credentials':
        return 'Incorrect email or password';
      case 'Network error':
        return 'Please check your internet connection';
      case 'Invalid request':
        return 'Please check your input fields';
      case 'Server timeout':
        return 'Server is not responding, please try again later';
      default:
        return e.message;
    }
  }

  String _getDashboardRouteForRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return '/admin_dashboard';
      case 'parent':
        return '/parent_dashboard';
      case 'teacher':
        return '/teacher_dashboard';
      default:
        throw Exception('Unknown user role: $role');
    }
  }

  String _getPasswordStrengthText(String password) {
    if (password.isEmpty) return 'Enter a password';
    if (password.length < 8) return 'Too short (min 8 chars)';
    if (!RegExp(r'[A-Z]').hasMatch(password)) return 'Needs uppercase letter';
    if (!RegExp(r'\d').hasMatch(password)) return 'Needs number';
    if (!RegExp(r'[@$!%*?&]').hasMatch(password)) return 'Needs special character';
    return 'Strong password';
  }

  Color _getPasswordStrengthColor(String password) {
    if (password.isEmpty) return Colors.grey;
    if (password.length < 8) return Colors.red;
    if (!RegExp(r'[A-Z]').hasMatch(password)) return Colors.orange;
    if (!RegExp(r'\d').hasMatch(password)) return Colors.orange;
    if (!RegExp(r'[@$!%*?&]').hasMatch(password)) return Colors.orange;
    return Colors.green;
  }

  Widget _buildInputField(String label, TextEditingController controller, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(letterSpacing: 1, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF0F0F0),
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your email';
            }
            if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
              return 'Please enter a valid email';
            }
            return null;
          },
          onChanged: (_) => setState(() => _errorMessage = null), // Clear error on input
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('PASSWORD', style: TextStyle(letterSpacing: 1, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          keyboardType: TextInputType.visiblePassword, // Improved keyboard type
          onChanged: (_) => setState(() => _errorMessage = null), // Clear error on input
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF0F0F0),
            hintText: 'Enter your password',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your password';
            }
            if (value.length < 8) {
              return 'Password must be at least 8 characters';
            }
            return null;
          },
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            _getPasswordStrengthText(_passwordController.text),
            style: TextStyle(
              color: _getPasswordStrengthColor(_passwordController.text),
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF5271FF),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),
                Center(child: Image.asset('assets/safenest.png', height: 120)),
                const SizedBox(height: 20),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 10),
                            const Center(
                              child: Text('Login', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 8),
                            const Center(child: Text('Sign in to continue', style: TextStyle(fontSize: 16, color: Colors.grey))),
                            const SizedBox(height: 32),
                            if (_errorMessage != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Colors.red, fontSize: 16),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            _buildInputField('EMAIL', _emailController, 'Enter your email'),
                            const SizedBox(height: 20),
                            _buildPasswordField(),
                            const SizedBox(height: 30),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5271FF),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Log in', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                            ),
                            const SizedBox(height: 20),
                            Center(
                              child: Text.rich(
                                TextSpan(
                                  text: 'Don\'t have an account? ',
                                  style: const TextStyle(color: Colors.grey),
                                  children: [
                                    TextSpan(
                                      text: 'Sign up',
                                      style: TextStyle(
                                        color: Theme.of(context).primaryColor,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                      ),
                                      recognizer: TapGestureRecognizer()..onTap = () => Navigator.pushReplacementNamed(context, '/register'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const ModalBarrier(
              dismissible: false,
              color: Colors.black54,
            ),
        ],
      ),
    );
  }
}