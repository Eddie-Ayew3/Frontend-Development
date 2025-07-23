import 'package:flutter/material.dart';
import 'package:safenest/api_services/file.dart';

class AddTeacherScreen extends StatefulWidget {
  const AddTeacherScreen({super.key});

  @override
  State<AddTeacherScreen> createState() => _AddTeacherScreenState();
}

class _AddTeacherScreenState extends State<AddTeacherScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullnameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _gradeController = TextEditingController();
  String? _selectedGrade;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _fullnameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _gradeController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
        await ApiService.safeApiCall(
          () => ApiService.createTeacher(
            fullname: _fullnameController.text,
            phone: _phoneController.text,
            email: _emailController.text,
            grade: _gradeController.text,
          ),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Teacher added successfully!')),
          );
          Navigator.pop(context);
        }
      } on ApiException catch (e) {
        if (mounted) {
          setState(() => _errorMessage = _mapErrorToMessage(e));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding teacher: $_errorMessage')),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _errorMessage = 'An unexpected error occurred');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('An unexpected error occurred')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
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
      default:
        return e.message;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF5271FF),
      appBar: AppBar(
        title: const Text('Add New Teacher'),
        centerTitle: true,
        backgroundColor: const Color(0xFF5271FF),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 3),
            Expanded(
              child: Container(
                width: double.infinity, // Ensures the container stretches horizontally
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
                        TextFormField(
                          controller: _fullnameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(16)),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter full name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(16)),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter phone number';
                            }
                            if (!RegExp(r'^\+?\d{10,15}$').hasMatch(value)) {
                              return 'Enter a valid phone number (10-15 digits)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(16)),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter email';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedGrade ?? (_gradeController.text.isEmpty ? null : _gradeController.text),
                          decoration: const InputDecoration(
                            labelText: 'Assigned Grade',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(16)),
                            ),
                          ),
                          items: List.generate(
                            6, // Configurable for elementary school
                            (index) => DropdownMenuItem(
                              value: 'Grade ${index + 1}',
                              child: Text('Grade ${index + 1}'),
                            ),
                          ),
                          onChanged: _isLoading
                              ? null
                              : (value) => setState(() {
                                    _selectedGrade = value;
                                    _gradeController.text = value ?? '';
                                  }),
                          validator: (value) => value == null ? 'Please select grade' : null,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _confirmSubmission,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF5271FF), // <-- Button background is now white
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Color(0xFF5271FF))
                              : const Text(
                                  'Save Teacher',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white, // <-- Text color is now primary blue
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
}