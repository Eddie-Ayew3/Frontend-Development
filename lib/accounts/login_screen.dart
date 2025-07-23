import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:safenest/features/user_management/admin_screen.dart';
import 'package:safenest/features/user_management/parent_screen.dart';
import 'package:safenest/features/user_management/teacher_screen.dart';
import 'package:safenest/api_services/file.dart';

// LoginScreen is the main login page widget
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controllers for email and password input fields
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // Key for form validation
  bool _isLoading = false; // Indicates if login is in progress
  bool _obscurePassword = true; // Toggles password visibility
  String? _errorMessage; // Stores error messages for display

  @override
  void dispose() {
    // Dispose controllers to free resources
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Handles login logic and navigation based on user role
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Call API to login and get user role
      final response = await ApiService.safeApiCall(() => ApiService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      ));

      final role = response['role'];
      if (role == null || role.isEmpty) {
        throw  ApiException('Invalid user role');
      }

      // Navigate to dashboard based on user role
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => _getDashboardForRole(role)),
      );
    } on ApiException catch (e) {
      // Show error if API throws an exception
      _showError(_mapErrorToMessage(e));
    } catch (_) {
      // Show generic error for unexpected exceptions
      _showError('An unexpected error occurred');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Displays error message in UI and as a SnackBar
  void _showError(String message) {
    if (!mounted) return;
    setState(() => _errorMessage = message);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login failed: $message')));
  }

  // Maps API error messages to user-friendly messages
  String _mapErrorToMessage(ApiException e) {
    switch (e.message) {
      case 'Invalid credentials':
        return 'Incorrect username or password';
      case 'Network error':
        return 'Please check your internet connection';
      default:
        return e.message;
    }
  }

  // Returns the dashboard widget based on user role
  Widget _getDashboardForRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return const AdminDashboard();
      case 'parent':
        return const ParentDashboard();
      case 'teacher':
        return const TeacherDashboard();
      default:
        throw Exception('Unknown user role: $role');
    }
  }

  // Navigates to the sign-up screen
  void _navigateToSignUp() {
    Navigator.pushNamed(context, '/register');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF5271FF),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // App logo
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
                        // Login title
                        const Center(
                          child: Text('Login', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 8),
                        // Subtitle
                        const Center(child: Text('Sign in to continue', style: TextStyle(fontSize: 16, color: Colors.grey))),
                        const SizedBox(height: 32),
                        // Error message display
                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 16), textAlign: TextAlign.center),
                          ),
                        // Username input field
                        _buildInputField('USERNAME', _emailController, 'Enter your username'),
                        const SizedBox(height: 20),
                        // Password input field
                        _buildPasswordField(),
                        const SizedBox(height: 30),
                        // Login button
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5271FF),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Log in', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                        ),
                        const SizedBox(height: 20),
                        // Forgot password button (currently shows a SnackBar)
                        Center(
                          child: TextButton(
                            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coming soon!'))),
                            child: const Text('Forgot Password?', style: TextStyle(color: Colors.grey)),
                          ),
                        ),
                        // Sign up link
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
                                  recognizer: TapGestureRecognizer()..onTap = _navigateToSignUp,
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
    );
  }

  // Builds a labeled input field with validation
  Widget _buildInputField(String label, TextEditingController controller, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(letterSpacing: 1, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF0F0F0),
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
        ),
      ],
    );
  }

  // Builds the password input field with show/hide toggle
  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('PASSWORD', style: TextStyle(letterSpacing: 1, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
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
          validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter your password' : null,
        ),
      ],
    );
  }
}

