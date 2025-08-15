import 'package:flutter/material.dart';
import 'package:safenest/Api_Service/New_api.dart';


class AddParentScreen extends StatefulWidget {
  final String token;

  const AddParentScreen({
    super.key,
    required this.token,
  });

  @override
  State<AddParentScreen> createState() => _AddParentScreenState();
}

class _AddParentScreenState extends State<AddParentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _fullnameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ApiService().addParent(
        email: _emailController.text.trim(),
        fullname: _fullnameController.text.trim(),
        phone: _phoneController.text.trim(),
        location: _locationController.text.trim(),
      );
      if (!mounted) return;
      await _showSuccessDialog('Parent added successfully!');
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (e.statusCode == 401 && mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
      if (mounted) {
        setState(() => _errorMessage = _mapErrorToMessage(e));
        await _showErrorDialog(_errorMessage!);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showSuccessDialog(String message) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _showErrorDialog(String message) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          if (_errorMessage != 'Session expired. Please login again.')
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _submitForm();
              },
              child: const Text('Retry'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _mapErrorToMessage(ApiException e) {
    if (e.statusCode == 400) return 'Invalid input. Please check the details.';
    if (e.statusCode == 401) return 'Session expired. Please login again.';
    if (e.statusCode == 409) return 'This email is already registered.';
    if (e.message.contains('network')) return 'Network error. Please check your connection.';
    return 'Error adding parent: ${e.message}';
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(prefixIcon, color: const Color(0xFF5271FF)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Future<void> _confirmSubmission() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Submission'),
        content: const Text('Are you sure you want to add this parent?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      _submitForm();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Parent'),
        backgroundColor: const Color(0xFF5271FF),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF5271FF)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(
                      controller: _fullnameController,
                      label: 'Full Name',
                      prefixIcon: Icons.person_outline,
                      validator: (value) => value == null || value.isEmpty ? 'Please enter full name' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter email';
                        }
                        if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter phone number';
                        }
                        if (!RegExp(r'^\+233\d{9}$').hasMatch(value)) {
                          return 'Enter a valid Ghana phone number (e.g., +233XXXXXXXXX)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _locationController,
                      label: 'Location',
                      prefixIcon: Icons.location_on_outlined,
                      validator: (value) => value == null || value.isEmpty ? 'Please enter location' : null,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _confirmSubmission,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5271FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                            )
                          : const Text(
                              'Save Parent',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}