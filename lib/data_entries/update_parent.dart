import 'package:flutter/material.dart';
import 'package:safenest/api/New_api.dart';

class UpdateParentScreen extends StatefulWidget {
  final String userId;
  final String token;
  final Map<String, dynamic>? currentParentData;

  const UpdateParentScreen({
    super.key,
    required this.userId,
    required this.token,
    this.currentParentData,
  });

  @override
  State<UpdateParentScreen> createState() => _UpdateParentScreenState();
}

class _UpdateParentScreenState extends State<UpdateParentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Initialize form with current values if available
    if (widget.currentParentData != null) {
      _phoneController.text = widget.currentParentData!['phone'] ?? '';
      _locationController.text = widget.currentParentData!['location'] ?? '';
    }
  }

  @override
  void dispose() {
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
      // Check token validity first
      final authStatus = await ApiService.checkAuthStatus();
      if (authStatus == null) {
        throw ApiException('Session expired. Please login again.');
      }

      await ApiService.safeApiCall(() => ApiService.updateParent(
            token: widget.token,
            userId: widget.userId,
            phone: _phoneController.text.trim(),
            location: _locationController.text.trim(),
          ));

      if (!mounted) return;
      _showSuccessDialog('Parent information updated successfully!');
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
                  _submitForm(); // Only retry if form is valid
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
  }

  String _mapErrorToMessage(ApiException e) {
    switch (e.message) {
      case 'Network error':
        return 'Please check your internet connection and try again.';
      case 'Invalid phone number':
        return 'Please enter a valid Ghana phone number (e.g., 0244123456 or +233244123456)';
      case 'Unauthorized':
      case 'You can only update your own profile.':
        return 'You are not authorized to perform this action';
      case 'Parent not found':
        return 'Parent account not found. Please contact support.';
      case 'Failed to update parent':
        return 'Failed to save changes. Please try again.';
      case 'Session expired':
        return 'Session expired. Please login again.';
      default:
        return e.message;
    }
  }

  Widget _buildPhoneField() {
    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      maxLength: 15,
      decoration: InputDecoration(
        labelText: 'Phone Number',
        prefixIcon: const Icon(Icons.phone_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
        counterText: '',
        hintText: '0244123456 or +233244123456',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter phone number';
        }
        if (!RegExp(r'^(\+233|0)\d{9}$').hasMatch(value)) {
          return 'Enter a valid Ghana phone number';
        }
        return null;
      },
    );
  }

  Widget _buildLocationField() {
    return TextFormField(
      controller: _locationController,
      decoration: InputDecoration(
        labelText: 'Location',
        prefixIcon: const Icon(Icons.location_on_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
        hintText: 'Enter your current location',
      ),
      maxLength: 100,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter location';
        }
        if (value.length < 3) {
          return 'Location must be at least 3 characters';
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
              'Update Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Profile'),
        backgroundColor: const Color(0xFF5271FF),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Updating your profile information',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              _buildPhoneField(),
              const SizedBox(height: 16),
              _buildLocationField(),
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