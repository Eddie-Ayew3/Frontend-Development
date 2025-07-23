import 'package:flutter/material.dart';
import 'package:safenest/api_services/file.dart';

class AddChildScreen extends StatefulWidget {
  const AddChildScreen({super.key});

  @override
  State<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullnameController = TextEditingController();
  String? _selectedGender;
  String? _selectedGrade;
  int? _parentId;
  List<Map<String, dynamic>> parents = [];
  bool _isLoading = false;
  bool _isLoadingParents = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchParents();
  }

  Future<void> _fetchParents() async {
    try {
      final profile = await ApiService.safeApiCall(ApiService.getParentProfile);
      if (mounted) {
        setState(() {
          _parentId = int.tryParse(profile['id']?.toString() ?? '0');
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _mapErrorToMessage(ApiException(e.toString()));
          _isLoadingParents = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading parents: $_errorMessage')),
        );
      }
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
        await ApiService.safeApiCall(
          () => ApiService.createChild(
            fullName: _fullnameController.text,
            gender: _selectedGender!,
            grade: _selectedGrade!,
            parentId: _parentId!,
          ),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Child added successfully!')),
          );
          Navigator.pop(context);
        }
      } on ApiException catch (e) {
        if (mounted) {
          setState(() => _errorMessage = _mapErrorToMessage(e));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding child: $_errorMessage')),
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
        content: const Text('Are you sure you want to save this child?'),
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
      case 'Invalid parent ID':
        return 'The selected parent is invalid';
      case 'Duplicate child':
        return 'A child with this name already exists';
      default:
        return e.message;
    }
  }

  @override
  void dispose() {
    _fullnameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF5271FF),
      appBar: AppBar(
        title: const Text('Add New Child'),
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
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.all(10),
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
                            labelText: 'Child Name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(16)),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter child name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedGender,
                          decoration: const InputDecoration(
                            labelText: 'Gender',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(16)),
                            ),
                          ),
                          items: ['Male', 'Female', 'Other']
                              .map(
                                (gender) => DropdownMenuItem(
                                  value: gender,
                                  child: Text(gender),
                                ),
                              )
                              .toList(),
                          onChanged: _isLoading ? null : (value) => setState(() => _selectedGender = value),
                          validator: (value) => value == null ? 'Please select gender' : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedGrade,
                          decoration: const InputDecoration(
                            labelText: 'Grade',
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
                          onChanged: _isLoading ? null : (value) => setState(() => _selectedGrade = value),
                          validator: (value) => value == null ? 'Please select grade' : null,
                        ), 
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _isLoading || _isLoadingParents ? null : _confirmSubmission,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5271FF),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Save Child', style: TextStyle(fontSize: 16,fontWeight: FontWeight.w600,
                                    color: Colors.white,)),
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