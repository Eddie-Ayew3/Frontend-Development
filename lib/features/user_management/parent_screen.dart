
// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:safenest/api_services/file.dart';
import 'package:safenest/features/dashboard/update_sections/update_parent.dart';
import 'package:safenest/features/user_management/change_password_screen.dart';

class ParentDashboard extends StatefulWidget {
  final String userId;
  const ParentDashboard({super.key, required this.userId});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  late Future<List<dynamic>> _childrenFuture;
  late Future<List<dynamic>> _pickupLogsFuture;
  String _parentName = 'Parent';
  String? _errorMessage;
  bool _isLoadingQR = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _childrenFuture = _fetchChildren();
      _pickupLogsFuture = _fetchPickupLogs();
    });
    try {
      final parentProfile = await ApiService.getParentProfile(userId: widget.userId);
      if (mounted) {
        setState(() {
          _parentName = parentProfile['fullname'] ?? 'Parent';
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _mapErrorToMessage(e);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: ${_mapErrorToMessage(e)}')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load profile';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load profile')),
        );
      }
    }
  }

  Future<List<dynamic>> _fetchChildren() async {
    try {
      return await ApiService.safeApiCall(() => ApiService.getParentChildren(userId: widget.userId));
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load children';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load children')),
        );
      }
      return [];
    }
  }

  Future<List<dynamic>> _fetchPickupLogs() async {
    try {
      return await ApiService.safeApiCall(() => ApiService.getPickupLogs());
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _errorMessage = _mapErrorToMessage(e));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load pickup logs: ${_mapErrorToMessage(e)}')),
        );
      }
      return [];
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Failed to load pickup logs');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load pickup logs')),
        );
      }
      return [];
    }
  }

  Future<void> _handleRefresh() async {
    await _loadData();
  }

  Future<void> _logout(BuildContext context) async {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await ApiService.logout();
      if (mounted) {
        Navigator.pop(context);
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (Route<dynamic> route) => false,
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: ${_mapErrorToMessage(e)}')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logout failed: An unexpected error occurred')),
        );
      }
    }
  }

  Future<void> _generateAndShowQRCode(BuildContext context, String childId, String childName) async {
    if (!mounted || _isLoadingQR) return;

    setState(() {
      _isLoadingQR = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.safeApiCall(
        () => ApiService.generateQRCode(int.parse(childId)),
      );

      final base64Image = response['qrCode'];
      if (base64Image == null || base64Image.isEmpty) {
        throw ApiException('Invalid QR code data received');
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('QR Code for $childName'),
            content: QRDisplayWidget(
              base64Image: base64Image,
              onRetry: () => _generateAndShowQRCode(context, childId, childName),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _mapErrorToMessage(e);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate QR code: ${_mapErrorToMessage(e)}')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An unexpected error occurred';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An unexpected error occurred')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingQR = false;
        });
      }
    }
  }

  String _mapErrorToMessage(ApiException e) {
    switch (e.message) {
      case 'Invalid child ID':
        return 'The provided child ID is invalid';
      case 'Network error':
        return 'Please check your internet connection';
      case 'Unauthorized':
        return 'Please log in again';
      case 'Child not found or not associated with this parent.':
        return 'The selected child is not associated with you';
      case 'Parent not found.':
        return 'Parent profile not found';
      default:
        return e.message;
    }
  }

  void _updateParent() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UpdateParentScreen(userId: widget.userId),
      ),
    ).then((result) {
      if (result == true && mounted) {
        _handleRefresh();
      }
    });
  }

  void _addChild() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddChildScreen(parentId: widget.userId),
      ),
    ).then((result) {
      if (result == true && mounted) {
        _handleRefresh();
      }
    });
  }

  void _changePassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
    ).then((result) {
      if (result == true && mounted) {
        _handleRefresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat.yMMMMd().add_jm().format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFF5271FF),
      appBar: AppBar(
        title: const Text('Parent Dashboard'),
        centerTitle: true,
        backgroundColor: const Color(0xFF5271FF),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'refresh') {
                _handleRefresh();
              } else if (value == 'add_child') {
                _addChild();
              } else if (value == 'update_profile') {
                _updateParent();
              } else if (value == 'change_password') {
                _changePassword();
              }
            },
            itemBuilder: (BuildContext context) => const [
              PopupMenuItem(value: 'refresh', child: Text('Refresh Data')),
              PopupMenuItem(value: 'add_child', child: Text('Add Child')),
              PopupMenuItem(value: 'update_profile', child: Text('Update Profile')),
              PopupMenuItem(value: 'change_password', child: Text('Change Password')),
            ],
          ),
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
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
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: IntrinsicHeight(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  '📅 $formattedDate',
                                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Hello, $_parentName!',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (_errorMessage != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Material(
                                      color: Colors.red[50],
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.error_outline, color: Colors.red, size: 22),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                _errorMessage!,
                                                style: const TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                const Text(
                                  'Recent Pickups',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 8),
                                FutureBuilder<List<dynamic>>(
                                  future: _pickupLogsFuture,
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return const Center(child: CircularProgressIndicator());
                                    } else if (snapshot.hasError) {
                                      final errorMessage = snapshot.error is ApiException
                                          ? _mapErrorToMessage(snapshot.error as ApiException)
                                          : 'Error: ${snapshot.error.toString()}';
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                        child: Material(
                                          color: Colors.red[50],
                                          borderRadius: BorderRadius.circular(12),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const Icon(Icons.error_outline, color: Colors.red, size: 22),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    errorMessage,
                                                    style: const TextStyle(
                                                      color: Colors.red,
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                      return const Center(child: Text('No pickup logs found'));
                                    }

                                    return ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: snapshot.data!.length,
                                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                                      itemBuilder: (context, index) {
                                        final log = snapshot.data![index];
                                        final childName = log['fullName'] ?? 'Unknown Child';
                                        final parentName = log['parentName'] ?? 'Unknown Parent';
                                        final dateTime = DateTime.tryParse(log['verifiedAt'] ?? '');
                                        final formattedTime = dateTime != null
                                            ? DateFormat('MMM d, h:mm a').format(dateTime)
                                            : 'Unknown time';
                                        return Card(
                                          child: ListTile(
                                            title: Text('$childName picked up by $parentName'),
                                            subtitle: Text(formattedTime),
                                            trailing: const Icon(
                                              Icons.check_circle,
                                              color: Colors.green,
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Generate Pickup QR Code',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                AbsorbPointer(
                                  absorbing: _isLoadingQR,
                                  child: Opacity(
                                    opacity: _isLoadingQR ? 0.6 : 1.0,
                                    child: FutureBuilder<List<dynamic>>(
                                      future: _childrenFuture,
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return const Center(child: CircularProgressIndicator());
                                        } else if (snapshot.hasError) {
                                          final errorMessage = snapshot.error is ApiException
                                              ? _mapErrorToMessage(snapshot.error as ApiException)
                                              : 'Error: ${snapshot.error.toString()}';
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                            child: Material(
                                              color: Colors.red[50],
                                              borderRadius: BorderRadius.circular(12),
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    const Icon(Icons.error_outline, color: Colors.red, size: 22),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        errorMessage,
                                                        style: const TextStyle(
                                                          color: Colors.red,
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                        textAlign: TextAlign.center,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                          return const Center(child: Text('No children found'));
                                        }

                                        return ListView.separated(
                                          shrinkWrap: true,
                                          physics: const NeverScrollableScrollPhysics(),
                                          itemCount: snapshot.data!.length,
                                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                                          itemBuilder: (context, index) {
                                            final child = snapshot.data![index];
                                            final childId = child['childID']?.toString() ?? 'unknown';
                                            final childName = child['fullname'] ?? 'Unknown Child';
                                            final childGrade = child['grade'] ?? 'Unknown Grade';
                                            return Card(
                                              child: ListTile(
                                                title: Text(childName),
                                                subtitle: Text(childGrade),
                                                trailing: _isLoadingQR
                                                    ? const CircularProgressIndicator()
                                                    : ElevatedButton(
                                                        onPressed: () => _generateAndShowQRCode(context, childId, childName),
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: const Color(0xFF5271FF),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(16),
                                                          ),
                                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                                        ),
                                                        child: const Text(
                                                          'Generate QR Code',
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            fontWeight: FontWeight.w600,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QRDisplayWidget extends StatelessWidget {
  final String base64Image;
  final VoidCallback? onRetry;

  const QRDisplayWidget({super.key, required this.base64Image, this.onRetry});

  @override
  Widget build(BuildContext context) {
    Uint8List? decodedImage;
    String? errorMessage;

    try {
      decodedImage = base64Image.contains(',')
          ? base64Decode(base64Image.split(',').last)
          : base64Decode(base64Image);
    } catch (e) {
      errorMessage = 'Failed to load QR code: ${e.toString()}';
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (errorMessage != null) ...[
          Text(
            errorMessage,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: ElevatedButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ),
        ] else if (decodedImage != null) ...[
          const Text(
            'Scan this QR at the gate',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          Image.memory(
            decodedImage,
            width: MediaQuery.of(context).size.width * 0.6,
            height: MediaQuery.of(context).size.width * 0.6,
          ),
        ],
      ],
    );
  }
}

class AddChildScreen extends StatefulWidget {
  final String parentId;
  const AddChildScreen({super.key, required this.parentId});

  @override
  State<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullnameController = TextEditingController();
  final TextEditingController _gradeController = TextEditingController();
  String? _selectedGrade;
  String? _selectedGender;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _fullnameController.dispose();
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
          () => ApiService.createChild(
            fullName: _fullnameController.text.trim(),
            gender: _selectedGender!,
            parentId: int.parse(widget.parentId),
            grade: _gradeController.text.trim(),
          ),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Child added successfully!')),
          );
          Navigator.pop(context, true); // Return true to trigger refresh
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
        content: const Text('Are you sure you want to add this child?'),
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
      case 'Invalid grade. Use \'Grade 1\' to \'Grade 5\'.':
        return 'Invalid grade. Use Grade 1 to Grade 5';
      case 'Parent not found.':
        return 'Parent ID not found';
      case 'Unauthorized':
        return 'Please log in again';
      case 'Duplicate child':
        return 'A child with this name already exists';
      case 'Invalid gender':
        return 'Invalid gender. Use Male, Female, or Other';
      default:
        return e.message;
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
        Text(
          label,
          style: const TextStyle(letterSpacing: 1, fontWeight: FontWeight.w500),
        ),
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
                              controller: _fullnameController,
                              label: 'FULL NAME',
                              hintText: 'Enter child\'s full name',
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter full name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            DropdownButtonFormField<String>(
                              value: _selectedGender,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFF0F0F0),
                                labelText: 'GENDER',
                                labelStyle: const TextStyle(letterSpacing: 1, fontWeight: FontWeight.w500),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              items: ['Male', 'Female', 'Other']
                                  .map((gender) => DropdownMenuItem(
                                        value: gender,
                                        child: Text(gender),
                                      ))
                                  .toList(),
                              onChanged: _isLoading
                                  ? null
                                  : (value) => setState(() => _selectedGender = value),
                              validator: (value) => value == null ? 'Please select gender' : null,
                            ),
                            const SizedBox(height: 20),
                            DropdownButtonFormField<String>(
                              value: _selectedGrade,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFF0F0F0),
                                labelText: 'GRADE',
                                labelStyle: const TextStyle(letterSpacing: 1, fontWeight: FontWeight.w500),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              items: List.generate(
                                5,
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
                                backgroundColor: const Color(0xFF5271FF),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text(
                                      'Save Child',
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
