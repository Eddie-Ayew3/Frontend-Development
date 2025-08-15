import 'package:flutter/material.dart';
import 'package:safenest/Api_Service/New_api.dart';

class UpdateTeacherScreen extends StatefulWidget {
  final String roleId;
  final String token;

  const UpdateTeacherScreen({
    super.key,
    required this.roleId,
    required this.token,
  });

  @override
  State<UpdateTeacherScreen> createState() => _UpdateTeacherScreenState();
}

class _UpdateTeacherScreenState extends State<UpdateTeacherScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  String? _selectedGrade;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Removed the aggressive session check
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

Future<void> _submitForm() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  try {
    // Convert userId to int to match backend
    final teacherId = int.tryParse(widget.roleId);
    if (teacherId == null) {
      throw Exception('Invalid teacher ID format');
    }

    await ApiService().updateTeacher(
      teacherId: teacherId,
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      grade: _selectedGrade,
      token: widget.token,
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
      decoration: InputDecoration(
        labelText: 'Phone Number',
        prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF5271FF)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
        hintText: 'e.g., +233XXXXXXXXX',
      ),
      keyboardType: TextInputType.phone,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter phone number';
        }
        return null;
      },
    );
  }

  Widget _buildGradeField() {
    return DropdownButtonFormField<String>(
      value: _selectedGrade,
      decoration: InputDecoration(
        labelText: 'Assigned Grade',
        prefixIcon: const Icon(Icons.school_outlined, color: Color(0xFF5271FF)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      ),
      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF5271FF)),
      items: List.generate(
        6,
        (index) => DropdownMenuItem(
          value: 'Grade ${index + 1}',
          child: Text('Grade ${index + 1}'),
        ),
      ),
      onChanged: _isLoading ? null : (value) => setState(() => _selectedGrade = value),
      validator: (value) => value == null ? 'Please select grade' : null,
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
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
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
        title: const Text('Update Teacher Profile'),
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
                      'Updating profile for Teacher ID: ${widget.roleId}',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),
                    _buildPhoneField(),
                    const SizedBox(height: 16),
                    _buildGradeField(),
                    const SizedBox(height: 32),
                    _buildSubmitButton(),
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