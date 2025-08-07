import 'package:flutter/material.dart';
import 'package:safenest/api/New_api.dart';

class AddChildScreen extends StatefulWidget {
  final String parentId;
  final String token;

  const AddChildScreen({
    super.key,
    required this.parentId,
    required this.token,
  });

  @override
  State<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullnameController = TextEditingController();
  final TextEditingController _gradeController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _fullnameController.dispose();
    _gradeController.dispose();
    _genderController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('Using token for create child: ${widget.token}'); // Debug log
      await ApiService.createChild(
        token: widget.token,
        parentId: widget.parentId,
        fullname: _fullnameController.text.trim(),
        grade: _gradeController.text.trim(),
        gender: _genderController.text.trim(),
      );

      if (!mounted) return;
      _showSuccessDialog('Child created successfully!');
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _errorMessage = _mapErrorToMessage(e));
        _showErrorDialog(_errorMessage!);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'An unexpected error occurred. Please try again.');
        _showErrorDialog(_errorMessage!);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showSuccessDialog(String message) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, true); // Return success to previous screen
            },
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
                Navigator.pop(context); // Close dialog
                if (_formKey.currentState!.validate()) {
                  _submitForm(); // Retry if form is valid
                }
              },
              child: const Text('Retry'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_errorMessage == 'Session expired. Please login again.' 
                ? 'OK' 
                : 'Cancel'),
          ),
        ],
      ),
    );

    if (_errorMessage == 'Session expired. Please login again.') {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  String _mapErrorToMessage(ApiException e) {
    switch (e.message) {
      case 'Network error':
        return 'Please check your internet connection and try again.';
      case 'Invalid grade. Use \'Grade 1\' to \'Grade 9\'':
        return 'Please select a valid grade (Grade 1 to Grade 9).';
      case 'Parent not found':
        return 'Parent not found. Please contact support.';
      case 'Unauthorized':
        return 'You are not authorized to perform this action.';
      case 'Failed to create child':
        return 'Failed to save child. Please try again.';
      case 'Session expired':
        return 'Session expired. Please login again.';
      default:
        return e.message;
    }
  }

  Widget _buildFullnameField() {
    return TextFormField(
      controller: _fullnameController,
      decoration: InputDecoration(
        labelText: 'Child Name',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter child name';
        }
        if (value.length < 2) {
          return 'Name must be at least 2 characters';
        }
        return null;
      },
    );
  }

  Widget _buildGradeField() {
    return TextFormField(
      controller: _gradeController,
      decoration: InputDecoration(
        labelText: 'Grade',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
        hintText: 'e.g., Grade 1',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter grade';
        }
        final validGrades = ['Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5', 
                           'Grade 6', 'Grade 7', 'Grade 8', 'Grade 9'];
        if (!validGrades.contains(value)) {
          return 'Please select a valid grade (Grade 1 to Grade 9)';
        }
        return null;
      },
    );
  }

  Widget _buildGenderField() {
    return TextFormField(
      controller: _genderController,
      decoration: InputDecoration(
        labelText: 'Gender',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
        hintText: 'e.g., Male or Female',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter gender';
        }
        if (!['Male', 'Female'].contains(value)) {
          return 'Gender must be Male or Female';
        }
        return null;
      },
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _submitForm,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF5271FF),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        minimumSize: const Size(double.infinity, 50),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            )
          : const Text(
              'Save Child',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Child'),
        backgroundColor: const Color(0xFF5271FF),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Parent ID: ${widget.parentId}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildFullnameField(),
                    const SizedBox(height: 20),
                    _buildGradeField(),
                    const SizedBox(height: 20),
                    _buildGenderField(),
                    const SizedBox(height: 32),
                    _buildSubmitButton(),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}