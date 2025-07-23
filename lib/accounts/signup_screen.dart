import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:safenest/api_services/file.dart';
import 'package:safenest/features/user_management/admin_screen.dart';
import 'package:safenest/features/user_management/parent_screen.dart';
import 'package:safenest/features/user_management/teacher_screen.dart';
import 'package:url_launcher/url_launcher.dart';

// SignUpScreen is the main registration page widget
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // Controllers for input fields
  final TextEditingController _fullnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // Key for form validation

  // UI state variables
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;
  String? _selectedRole;
  String? _errorMessage;

  @override
  void dispose() {
    // Dispose controllers to free resources
    _fullnameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Handles sign up logic and navigation
  Future<void> _handleSignUp() async {
    // Validate form fields
    if (!_formKey.currentState!.validate()) return;

    // Check if terms are accepted
    if (!_acceptedTerms) {
      setState(() => _errorMessage = 'Please accept the terms and conditions');
      return;
    }

    // Check if passwords match
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }

    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Call API to register user
      final response = await ApiService.safeApiCall(() => ApiService.register(
            fullname: _fullnameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            role: _selectedRole!,
          ));

      if (!mounted) return;

      // Check if token is received
      if (response['token'] == null) {
        throw ApiException('No token received');
      }

      // Store auth token
      ApiService.setAuthToken(response['token']);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signup successful!')),
      );

      // Navigate to dashboard based on role (no email verification)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => _getDashboardForRole(_selectedRole!)),
      );
    } on ApiException catch (e) {
      // Show API error
      if (mounted) {
        setState(() => _errorMessage = _mapErrorToMessage(e));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Signup failed: ${_mapErrorToMessage(e)}')),
        );
      }
    } catch (e) {
      // Show generic error
      if (mounted) {
        setState(() => _errorMessage = 'An unexpected error occurred');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An unexpected error occurred')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Maps API error messages to user-friendly messages
  String _mapErrorToMessage(ApiException e) {
    switch (e.message) {
      case 'Email already exists':
        return 'This email is already registered';
      case 'Invalid role':
        return 'Selected role is not valid';
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
        throw Exception('Invalid role: $role');
    }
  }

  // Shows a dialog with terms and privacy policy links
  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms and Conditions'),
        content: SingleChildScrollView(
          child: Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text: 'By creating an account, you agree to our ',
                  style: TextStyle(fontSize: 16),
                ),
                TextSpan(
                  text: 'Terms of Service',
                  style: const TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () async {
                      final url = Uri.parse('https://example.com/terms');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      }
                    },
                ),
                const TextSpan(
                  text: ' and acknowledge that you have read our ',
                  style: TextStyle(fontSize: 16),
                ),
                TextSpan(
                  text: 'Privacy Policy',
                  style: const TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () async {
                      final url = Uri.parse('https://example.com/privacy');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      }
                    },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Returns a password strength message
  String _getPasswordStrengthText(String password) {
    if (password.isEmpty) return 'Enter a password';
    if (password.length < 8) return 'Too short (min 8 chars)';
    if (!RegExp(r'[A-Z]').hasMatch(password)) return 'Needs uppercase letter';
    if (!RegExp(r'\d').hasMatch(password)) return 'Needs number';
    if (!RegExp(r'[@$!%*?&]').hasMatch(password)) return 'Needs special character';
    return 'Strong password';
  }

  // Returns a color based on password strength
  Color _getPasswordStrengthColor(String password) {
    if (password.isEmpty) return Colors.grey;
    if (password.length < 8) return Colors.red;
    if (!RegExp(r'[A-Z]').hasMatch(password)) return Colors.orange;
    if (!RegExp(r'\d').hasMatch(password)) return Colors.orange;
    if (!RegExp(r'[@$!%*?&]').hasMatch(password)) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF5271FF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 40),
              // App logo
              Center(
                child: Image.asset('assets/safenest.png', height: 120),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: AbsorbPointer(
                  absorbing: _isLoading, // Disable form while loading
                  child: Opacity(
                    opacity: _isLoading ? 0.6 : 1.0, // Dim form while loading
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Title
                          const Center(
                            child: Text(
                              'Create New Account',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Error message display
                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          // Full name input
                          _buildLabel('FULL NAME'),
                          _buildTextField(
                            controller: _fullnameController,
                            hintText: 'Enter your full name',
                            fillColor: Colors.grey[200]!, // <-- Use a light grey background for Full Name
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your name';
                              }
                              if (value.trim().length < 3) {
                                return 'Name must be at least 3 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          // Email input
                          _buildLabel('EMAIL'),
                          _buildTextField(
                            controller: _emailController,
                            hintText: 'Enter your email',
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter an email';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                  .hasMatch(value)) {
                                return 'Enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          // Role dropdown
                          _buildLabel('ROLE'),
                          _buildRoleDropdown(),
                          const SizedBox(height: 20),
                          // Password input
                          _buildLabel('PASSWORD'),
                          _buildPasswordField(
                            controller: _passwordController,
                            hintText: 'Enter your password',
                            obscureText: _obscurePassword,
                            onToggleVisibility: () =>
                                setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          // Password strength indicator
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _getPasswordStrengthText(_passwordController.text),
                              style: TextStyle(
                                color: _getPasswordStrengthColor(
                                    _passwordController.text),
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Confirm password input
                          _buildLabel('CONFIRM PASSWORD'),
                          _buildPasswordField(
                            controller: _confirmPasswordController,
                            hintText: 'Confirm your password',
                            obscureText: _obscureConfirmPassword,
                            onToggleVisibility: () => setState(
                                () => _obscureConfirmPassword = !_obscureConfirmPassword),
                          ),
                          const SizedBox(height: 16),
                          // Terms and conditions checkbox
                          Row(
                            children: [
                              Checkbox(
                                value: _acceptedTerms,
                                onChanged: (value) =>
                                    setState(() => _acceptedTerms = value ?? false),
                              ),
                              Expanded(
                                child: Text.rich(
                                  TextSpan(
                                    text: 'I agree to the ',
                                    children: [
                                      TextSpan(
                                        text: 'Terms and Conditions',
                                        style: TextStyle(
                                          color: Theme.of(context).primaryColor,
                                          decoration: TextDecoration.underline,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = _showTermsDialog,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Sign up button
                          ElevatedButton(
                            onPressed: _isLoading ? null : _handleSignUp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5271FF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text(
                                    'Sign up',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 20),
                          // Login link
                          Center(
                            child: Text.rich(
                              TextSpan(
                                text: 'Already have an account? ',
                                style: const TextStyle(color: Colors.grey),
                                children: [
                                  TextSpan(
                                    text: 'Login instead',
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () => Navigator.pop(context),
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
      ),
    );
  }

  // Builds a label for input fields
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          letterSpacing: 1,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // Builds a generic text input field with validation
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    Color fillColor = const Color(0xFFF0F0F0), // <-- Add this line
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        filled: true,
        fillColor: fillColor, // <-- Use the fillColor parameter
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      validator: validator,
    );
  }

  // Builds a password input field with show/hide toggle and validation
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF0F0F0),
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        suffixIcon: IconButton(
          icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
          onPressed: onToggleVisibility,
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a password';
        }
        if (value.length < 8) {
          return 'Password must be at least 8 characters';
        }
        if (!RegExp(r'^(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&]).{8,}$')
            .hasMatch(value)) {
          return 'Must include uppercase, number, and special character';
        }
        return null;
      },
    );
  }

  // Builds the role dropdown field
  Widget _buildRoleDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedRole,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF0F0F0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      hint: const Text('Select your role'),
      items: const [
        DropdownMenuItem(value: 'Parent', child: Text('Parent')),
        DropdownMenuItem(value: 'Teacher', child: Text('Teacher')),
        DropdownMenuItem(value: 'Admin', child: Text('Admin')),
      ],
      onChanged: (value) => setState(() => _selectedRole = value),
      validator: (value) => value == null ? 'Please select a role' : null,
    );
  }
}

class EmailVerificationScreen extends StatelessWidget {
  const EmailVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Email Verification Screen (to be removed)'),
      ),
    );
  }
}