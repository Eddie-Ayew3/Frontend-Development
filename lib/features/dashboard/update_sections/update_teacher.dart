
import 'package:flutter/material.dart';
import 'package:safenest/api_services/file.dart';

class UpdateTeacherScreen extends StatefulWidget {
  final String userId;
  const UpdateTeacherScreen({super.key, required this.userId});

  @override
  State<UpdateTeacherScreen> createState() => _UpdateTeacherScreenState();
}

class _UpdateTeacherScreenState extends State<UpdateTeacherScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _gradeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTeacherProfile();
  }

  Future<void> _loadTeacherProfile() async {
    try {
      final profile = await ApiService.getTeacherProfile(userId: widget.userId);
      if (mounted) {
        setState(() {
          _phoneController.text = profile['phone'] ?? '';
          _gradeController.text = profile['grade'] ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Failed to load profile: ${e.toString()}');
      }
    }
  }

  String _mapErrorToMessage(ApiException e) {
    switch (e.message) {
      case 'Invalid phone number':
        return 'Please enter a valid phone number';
      case 'Network error':
        return 'Please check your internet connection';
      case 'Unauthorized':
        return 'Please log in again';
      case 'You can only update your own profile.':
        return 'You can only update your own profile';
      case 'Teacher not found.':
        return 'Profile not found';
      case 'Invalid grade. Use \'Grade 1\' to \'Grade 5\'.':
        return 'Invalid grade. Use Grade 1 to Grade 5';
      default:
        return e.message;
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
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
          () => ApiService.updateTeacher(
            userId: widget.userId,
            phone: _phoneController.text.trim(),
            grade: _gradeController.text.trim(),
          ),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Details updated successfully!')),
          );
          Navigator.pop(context, true); // Return true to trigger refresh
        }
      } on ApiException catch (e) {
        if (mounted) {
          setState(() => _errorMessage = _mapErrorToMessage(e));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating details: $_errorMessage')),
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
        content: const Text('Are you sure you want to update your details?'),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(letterSpacing: 1, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF0F0F0),
            hintText: hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: validator,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF5271FF),
      appBar: AppBar(
        title: const Text('Update Details'),
        centerTitle: true,
        backgroundColor: const Color(0xFF5271FF),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 3),
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
                child: AbsorbPointer(
                  absorbing: _isLoading,
                  child: Opacity(
                    opacity: _isLoading ? 0.6 : 1.0,
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
                            _buildTextField(
                              controller: _phoneController,
                              label: 'PHONE NUMBER',
                              hintText: 'Enter phone number',
                              keyboardType: TextInputType.phone,
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
                            const SizedBox(height: 20),
                            _buildTextField(
                              controller: _gradeController,
                              label: 'GRADE',
                              hintText: 'Enter grade (e.g., Grade 1)',
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter grade';
                                }
                                if (!RegExp(r'^Grade [1-5]$').hasMatch(value)) {
                                  return 'Enter a valid grade (Grade 1 to Grade 5)';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _confirmSubmission,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5271FF),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text(
                                      'Save Details',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
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
