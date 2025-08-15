import 'package:flutter/material.dart';
import 'package:safenest/Api_Service/New_api.dart';


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
  final List<String> _genderOptions = ['Male', 'Female', 'Other'];

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
      final response = await ApiService().addChild(
        fullname: _fullnameController.text.trim(),
        grade: _gradeController.text.trim(),
        gender: _genderController.text.trim(),
        parentID: widget.parentId,
      );
      
      if (!mounted) return;
      
      await _showSuccessDialog(
        'Child added successfully!\nChild ID: ${response['id']}'
      );
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
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true);
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
                Navigator.pop(context);
                if (_formKey.currentState!.validate()) {
                  _submitForm();
                }
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
    if (e.message.contains('network')) return 'Network error. Please check your connection.';
    return 'Error adding child: ${e.message}';
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

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: _genderController.text.isEmpty ? null : _genderController.text,
      decoration: InputDecoration(
        labelText: 'Gender',
        prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF5271FF)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      ),
      items: _genderOptions.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _genderController.text = newValue ?? '';
        });
      },
      validator: (value) => value == null || value.isEmpty ? 'Please select gender' : null,
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
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF5271FF)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Parent ID: ${widget.parentId}',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _fullnameController,
                      label: 'Full Name',
                      prefixIcon: Icons.person_outline,
                      validator: (value) => 
                        value == null || value.isEmpty ? 'Please enter full name' : null,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _gradeController,
                      label: 'Grade',
                      prefixIcon: Icons.school_outlined,
                      validator: (value) => 
                        value == null || value.isEmpty ? 'Please enter grade' : null,
                    ),
                    const SizedBox(height: 20),
                    _buildGenderDropdown(),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5271FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
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
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
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