import 'package:flutter/material.dart';
import 'package:safenest/api/New_api.dart';

class AddTeacherScreen extends StatefulWidget {
  final String token;

  const AddTeacherScreen({
    super.key,
    required this.token,
  });

  @override
  State<AddTeacherScreen> createState() => _AddTeacherScreenState();
}

class _AddTeacherScreenState extends State<AddTeacherScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullnameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String? _selectedGrade;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _fullnameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ApiService.safeApiCall(() => ApiService.createTeacher(
            token: widget.token,
            fullname: _fullnameController.text.trim(),
            phone: _phoneController.text.trim(),
            email: _emailController.text.trim(),
            grade: _selectedGrade!,
          ));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Teacher added successfully!')),
      );
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _errorMessage = _mapErrorToMessage(e));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding teacher: $_errorMessage'),
            action: e.message == 'Network error'
                ? SnackBarAction(label: 'Retry', onPressed: _submitForm)
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
            action: SnackBarAction(label: 'Retry', onPressed: _submitForm),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmSubmission() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Submission'),
        content: const Text('Are you sure you want to add this teacher?'),
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

  String _mapErrorToMessage(ApiException e) {
    switch (e.message) {
      case 'Network error':
        return 'Please check your internet connection';
      case 'Duplicate email':
        return 'This email is already registered';
      case 'Invalid phone number':
        return 'Please enter a valid phone number';
      case 'Unauthorized':
        return 'You are not authorized to perform this action';
      default:
        return e.message;
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Teacher')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                    ),
                  ),
                ),
              _buildTextField(
                controller: _fullnameController,
                label: 'Full Name',
                validator: (value) =>
                    value == null || value.isEmpty ? 'Please enter full name' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number',
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
                controller: _emailController,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter email';
                  }
                  if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
                      .hasMatch(value)) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedGrade,
                decoration: const InputDecoration(
                  labelText: 'Assigned Grade',
                  border: OutlineInputBorder(),
                ),
                items: List.generate(
                  6,
                  (index) => DropdownMenuItem(
                    value: 'Grade ${index + 1}',
                    child: Text('Grade ${index + 1}'),
                  ),
                ),
                onChanged: _isLoading
                    ? null
                    : (value) => setState(() => _selectedGrade = value),
                validator: (value) => value == null ? 'Please select grade' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _confirmSubmission,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Save Teacher'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}