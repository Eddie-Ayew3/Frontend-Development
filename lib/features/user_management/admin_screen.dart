import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:safenest/api_services/file.dart';
import 'package:safenest/features/dashboard/new_sections/child_dashboard.dart';
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
        Navigator.pop(context); // Close the loading dialog
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
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                        maxHeight: constraints.maxHeight,
                      ),
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
                                    icon: data[index]['icon'] is IconData
                                        ? data[index]['icon']
                                        : Icons.info, // fallback icon
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
                                    return _buildActivityCard(
                                      '$childName picked up by $parentName',
                                      formattedTime,
                                    );
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