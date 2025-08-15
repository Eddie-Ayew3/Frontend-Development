import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:safenest/Api_Service/New_api.dart';
import 'package:safenest/Api_Service/pickup_log.dart';

class DashboardStats {
  final int totalParents;
  final int totalTeachers;
  final int totalChildren;
  final int totalPickups;
  final String message;

  DashboardStats({
    required this.totalParents,
    required this.totalTeachers,
    required this.totalChildren,
    required this.totalPickups,
    required this.message,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalParents: json['totalParents'] ?? 0,
      totalTeachers: json['totalTeachers'] ?? 0,
      totalChildren: json['totalChildren'] ?? 0,
      totalPickups: json['totalPickups'] ?? 0,
      message: json['message'] ?? 'No message',
    );
  }
}

class AdminDashboard extends StatefulWidget {
  final String email;
  final String fullname;
  final String token;

  const AdminDashboard({
    super.key,
    required this.email,
    required this.fullname,
    required this.token,
  });

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  late Future<DashboardStats> _dashboardStats;
  late Future<List<PickupLog>> _pickupLogs;
  bool _isLoading = false;

  // Modifiable: Web dashboard URL for admin error message
  static const String adminWebUrl = 'https://admin.mydomain.com';

  // Modifiable: Minimum screen width (in pixels) for admin dashboard access
  static const double minAdminWidth = 600.0;

  @override
  void initState() {
    super.initState();
    _dashboardStats = _fetchDashboardStats();
    _pickupLogs = _fetchPickupLogs();
  }

  Future<DashboardStats> _fetchDashboardStats() async {
    try {
      final response = await ApiService().getAdminDashboard();
      return DashboardStats.fromJson(response);
    } catch (e) {
      if (e is ApiException && e.statusCode == 401) {
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        }
      }
      throw ApiException('Failed to load dashboard stats: ${e.toString()}');
    }
  }

  Future<List<PickupLog>> _fetchPickupLogs() async {
    try {
      return await ApiService().getPickupLogs();
    } catch (e) {
      if (e is ApiException && e.statusCode == 401 && mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
      throw ApiException('Failed to load pickup logs: ${e.toString()}');
    }
  }

  Future<void> _refreshDashboard() async {
    setState(() {
      _isLoading = true;
      _dashboardStats = _fetchDashboardStats();
      _pickupLogs = _fetchPickupLogs();
    });
    await Future.wait([_dashboardStats, _pickupLogs]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await ApiService().logout();
      if (!context.mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if running on mobile (non-web) platform
    if (!kIsWeb) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 80, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Admins are restricted on mobile. Please use the web dashboard.',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Visit: $adminWebUrl',
                  style: const TextStyle(color: Colors.blue, fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5271FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Return to Login', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Check screen size for web platform
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < minAdminWidth) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.desktop_mac, size: 80, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Please use a tablet or desktop to access the admin dashboard.',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Current screen width: ${screenWidth.toStringAsFixed(0)}px (minimum required: $minAdminWidth px)',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5271FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Return to Login', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Main dashboard content (unchanged from original)
    return Scaffold(
      appBar: AppBar(
        title: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 18),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'ADMINISTRATOR',
            style: TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshDashboard,
            tooltip: 'Refresh data',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshDashboard,
        color: Colors.blue,
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, ${widget.fullname}!',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    Text(
                      widget.email,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 20),
                    FutureBuilder<DashboardStats>(
                      future: _dashboardStats,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return _buildErrorState(snapshot.error.toString());
                        }
                        if (!snapshot.hasData) {
                          return _buildEmptyState();
                        }
                        final stats = snapshot.data!;
                        return GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          children: [
                            _buildStatCard(
                              icon: Icons.supervisor_account,
                              value: stats.totalParents.toString(),
                              label: 'Parents',
                              color: Colors.blue,
                            ),
                            _buildStatCard(
                              icon: Icons.school,
                              value: stats.totalTeachers.toString(),
                              label: 'Teachers',
                              color: Colors.green,
                            ),
                            _buildStatCard(
                              icon: Icons.child_care,
                              value: stats.totalChildren.toString(),
                              label: 'Children',
                              color: Colors.orange,
                            ),
                            _buildStatCard(
                              icon: Icons.directions_bus,
                              value: stats.totalPickups.toString(),
                              label: 'Pickups',
                              color: Colors.purple,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          context,
                          icon: Icons.person_add,
                          label: 'Add Parent',
                          onPressed: () => Navigator.pushNamed(
                            context,
                            '/new_parent',
                            arguments: {'token': widget.token},
                          ),
                        ),
                        _buildActionButton(
                          context,
                          icon: Icons.person_add_alt_1,
                          label: 'Add Teacher',
                          onPressed: () => Navigator.pushNamed(
                            context,
                            '/new_teacher',
                            arguments: {'token': widget.token},
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Recent Pickup Logs',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 10),
                    FutureBuilder<List<PickupLog>>(
                      future: _pickupLogs,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return _buildErrorState(snapshot.error.toString());
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return _buildEmptyState();
                        }
                        final logs = snapshot.data!;
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: logs.length,
                          itemBuilder: (context, index) {
                            final log = logs[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                              child: ListTile(
                                title: Text(log.childName),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Parent: ${log.parentName}'),
                                    Text('Verified by: ${log.verifiedBy}'),
                                  ],
                                ),
                                trailing: Text(
                                  DateFormat('MMM d, hh:mm a').format(log.verifiedAt),
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              const Center(child: CircularProgressIndicator(color: Colors.blue)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 50),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Error loading data\n${_formatErrorMessage(error)}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _refreshDashboard,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  String _formatErrorMessage(String error) {
    if (error.contains('401')) return 'Session expired. Please login again.';
    if (error.contains('network')) return 'Network error. Check your connection.';
    return error;
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, color: Colors.blue, size: 50),
          SizedBox(height: 16),
          Text('No data available'),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 24),
      label: Text(label),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}