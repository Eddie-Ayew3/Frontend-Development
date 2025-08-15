import 'package:flutter/material.dart';
import 'package:safenest/Api_Service/New_api.dart';

class UpdateParentScreen extends StatefulWidget {

  final String roleId;
  final String token;

  const UpdateParentScreen({
    super.key,
    required this.roleId,
    required this.token,
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
      final parentId = int.tryParse(widget.roleId);
      if (parentId == null) {
        throw Exception('Invalid parent ID format');
      }

      await ApiService().updateParent(
        parentId: parentId,
        token: widget.token,
        phone: _phoneController.text.trim(),
        location: _locationController.text.trim(),
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.message);
        _showErrorSnackbar(e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
        _showErrorSnackbar('An unexpected error occurred');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      maxLength: 15,
      decoration: InputDecoration(
        labelText: 'Phone Number',
        prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF5271FF)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
        counterText: '',
        hintText: '024********* or +233*********',
      ),
      validator: (value) {
        if (value != null && value.isNotEmpty && !RegExp(r'^(\+233|0)\d{9}$').hasMatch(value)) {
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
        prefixIcon: const Icon(Icons.location_on_outlined, color: Color(0xFF5271FF)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
        hintText: 'Enter your current location',
      ),
      maxLength: 100,
      validator: (value) {
        if (value != null && value.isNotEmpty && value.length < 3) {
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        title: const Text('Update Parent Profile'),
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
                    Text(
                      'Updating profile for Parent ID: ${widget.roleId}',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
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