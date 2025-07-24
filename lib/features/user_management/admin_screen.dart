
// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:safenest/api_services/file.dart';
import 'package:safenest/features/dashboard/new_sections/parent_dashboard.dart';
import 'package:safenest/features/dashboard/new_sections/teacher_dashboard.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  late Future<List<Map<String, dynamic>>> _statsFuture;
  late Future<List<dynamic>> _pickupLogsFuture;
  String _adminName = 'Admin';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _statsFuture = _fetchStats();
      _pickupLogsFuture = _fetchPickupLogs();
    });
    try {
      final adminProfile = await ApiService.getAdminProfile();
      if (mounted) {
        setState(() {
          _adminName = adminProfile['fullName'] ?? 'Admin';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load profile: ${e.toString()}';
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchStats() async {
    try {
      return await ApiService.safeApiCall(() => ApiService.getAdminStats());
    } on ApiException catch (e) {
      throw ApiException('Failed to load stats: ${e.message}', statusCode: e.statusCode);
    } catch (e) {
      throw ApiException('Failed to load stats: ${e.toString()}');
    }
  }

  Future<List<dynamic>> _fetchPickupLogs() async {
    try {
      return await ApiService.safeApiCall(() => ApiService.getPickupLogs());
    } on ApiException catch (e) {
      throw ApiException('Failed to load pickup logs: ${e.message}', statusCode: e.statusCode);
    } catch (e) {
      throw ApiException('Failed to load pickup logs: ${e.toString()}');
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

  String _mapErrorToMessage(Object error) {
    if (error is ApiException) {
      switch (error.message) {
        case 'Network error':
          return 'Please check your internet connection';
        case 'Unauthorized':
          return 'Please log in again';
        default:
          return error.message;
      }
    }
    return error.toString();
  }

  Future<void> createParent() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddParentScreen()),
    );
    if (result == true && mounted) {
      _handleRefresh();
    }
  }

  Future<void> createTeacher() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddTeacherScreen()),
    );
    if (result == true && mounted) {
      _handleRefresh();
    }
  }

  Future<void> createChild() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddChildScreen()),
    );
    if (result == true && mounted) {
      _handleRefresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat.yMMMMd().add_jm().format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFF5271FF),
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        centerTitle: true,
        backgroundColor: const Color(0xFF5271FF),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'refresh') _handleRefresh();
              if (value == 'add_parent') createParent();
              if (value == 'add_teacher') createTeacher();
              if (value == 'add_child') createChild();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'refresh', child: Text('Refresh Data')),
              PopupMenuItem(value: 'add_parent', child: Text('Add Parent')),
              PopupMenuItem(value: 'add_teacher', child: Text('Add Teacher')),
              PopupMenuItem(value: 'add_child', child: Text('Add Child')),
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
                  child: LayoutBuilder(builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: IntrinsicHeight(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                '📅 $formattedDate',
                                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '👋 Hello, $_adminName!',
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
                              FutureBuilder<List<Map<String, dynamic>>>(
                                future: _statsFuture,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(child: CircularProgressIndicator());
                                  }
                                  if (snapshot.hasError) {
                                    final error = _mapErrorToMessage(snapshot.error!);
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
                                                  'Error: $error',
                                                  style: const TextStyle(
                                                    color: Colors.red,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              ElevatedButton(
                                                onPressed: _handleRefresh,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF5271FF),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                ),
                                                child: const Text('Retry', style: TextStyle(color: Colors.white)),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  final data = snapshot.data;
                                  if (data == null || data.isEmpty) {
                                    return const Center(child: Text('No stats available'));
                                  }
                                  return GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: data.length,
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      mainAxisSpacing: 16,
                                      crossAxisSpacing: 16,
                                      childAspectRatio: 1.3,
                                    ),
                                    itemBuilder: (context, index) => _buildStatCard(
                                      label: data[index]['label'],
                                      count: data[index]['count'].toString(),
                                      icon: data[index]['icon'] is IconData ? data[index]['icon'] : Icons.info,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 32),
                              const Text(
                                'Recent Activity',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              FutureBuilder<List<dynamic>>(
                                future: _pickupLogsFuture,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(child: CircularProgressIndicator());
                                  }
                                  if (snapshot.hasError) {
                                    final error = _mapErrorToMessage(snapshot.error!);
                                    return Center(
                                      child: Column(
                                        children: [
                                          Text('Error: $error'),
                                          const SizedBox(height: 16),
                                          ElevatedButton(
                                            onPressed: _handleRefresh,
                                            child: const Text('Retry'),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                  final logs = snapshot.data;
                                  if (logs == null || logs.isEmpty) {
                                    return const Center(child: Text('No recent pickups'));
                                  }
                                  return Column(
                                    children: logs.map((log) {
                                      final childName = log['fullName'] ?? 'Unknown';
                                      final parentName = log['parentName'] ?? 'Unknown';
                                      final dateTime = DateTime.tryParse(log['verifiedAt'] ?? '');
                                      final formattedTime = dateTime != null
                                          ? DateFormat('MMM d, h:mm a').format(dateTime)
                                          : 'Unknown time';
                                      return _buildActivityCard('$childName picked up by $parentName', formattedTime);
                                    }).toList(),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({required String label, required String count, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: const Color(0xFF5271FF)),
          const SizedBox(height: 12),
          Text(count, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildActivityCard(String title, String subtitle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: const Icon(Icons.access_time, color: Color(0xFF5271FF)),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.keyboard_arrow_right),
      ),
    );
  }
}

class AddChildScreen extends StatefulWidget {
  const AddChildScreen({super.key});

  @override
  State<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _parentIdController = TextEditingController();
  final TextEditingController _gradeController = TextEditingController();
  String? _selectedGender;
  String? _selectedGrade;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _fullnameController.dispose();
    _emailController.dispose();
    _parentIdController.dispose();
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
        // Parse the parent ID string to an integer
      final parentId = int.tryParse(_parentIdController.text.trim());
      if (parentId == null) {
        throw ApiException('Invalid parent ID format');
      }

        await ApiService.safeApiCall(
          () => ApiService.createChild(
            fullName: _fullnameController.text.trim(),
            email: _emailController.text.trim(),
            gender: _selectedGender!,
            parentId: parentId,
            grade: _gradeController.text.trim(),
          ),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Child added successfully!')),
          );
          Navigator.pop(context, true);
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
      case 'Email already in use.':
        return 'This email is already registered';
      case 'Invalid grade. Use \'Grade 1\' to \'Grade 5\'.':
        return 'Invalid grade. Use Grade 1 to Grade 5';
      case 'Parent not found.':
        return 'Parent ID not found';
      case 'Unauthorized':
        return 'Please log in again';
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
                            _buildTextField(
                              controller: _emailController,
                              label: 'EMAIL',
                              hintText: 'Enter child\'s email',
                              keyboardType: TextInputType.emailAddress,
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
                            const SizedBox(height: 20),
                            _buildTextField(
                              controller: _parentIdController,
                              label: 'PARENT ID',
                              hintText: 'Enter parent ID',
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter parent ID';
                                }
                                if (!RegExp(r'^\d+$').hasMatch(value)) {
                                  return 'Enter a valid parent ID (numbers only)';
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
