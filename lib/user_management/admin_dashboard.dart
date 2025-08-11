import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:safenest/api/New_api.dart';
import 'package:safenest/api/pickup_log.dart';

/// Data model for admin dashboard statistics
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

  /// Creates a DashboardStats instance from JSON data
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

/// Admin dashboard screen showing system statistics and management options
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

  @override
  void initState() {
    super.initState();
    _dashboardStats = _fetchDashboardStats();
    _pickupLogs = _fetchPickupLogs();
  }

  /// Fetches dashboard statistics from the API
  Future<DashboardStats> _fetchDashboardStats() async {
    try {
      final response = await ApiService.getAdminDashboard(widget.token);
      return DashboardStats.fromJson(response);
    } catch (e) {
      throw ApiException('Failed to load dashboard stats: ${e.toString()}');
    }
  }

  /// Fetches pickup logs from the API
  Future<List<PickupLog>> _fetchPickupLogs() async {
    try {
      final response = await ApiService.getPickupLogs(widget.token);
      return (response as List).map((log) => PickupLog.fromJson(log)).toList();
    } catch (e) {
      throw ApiException('Failed to load pickup logs: ${e.toString()}');
    }
  }

  /// Refreshes dashboard data
  Future<void> _refreshDashboard() async {
    setState(() {
      _dashboardStats = _fetchDashboardStats();
      _pickupLogs = _fetchPickupLogs();
    });
  }

  /// Handles user logout
  Future<void> _handleLogout(BuildContext context) async {
    try {
      await ApiService.logout();
      if (!context.mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
        child: FutureBuilder<DashboardStats>(
          future: _dashboardStats,
          builder: (context, snapshot) {
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildDashboardContent(snapshot),
            );
          },
        ),
      ),
    );
  }

  /// Builds the appropriate content based on the snapshot state
  Widget _buildDashboardContent(AsyncSnapshot<DashboardStats> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    } else if (snapshot.hasError) {
      return _buildErrorState(snapshot.error.toString());
    } else if (!snapshot.hasData) {
      return _buildEmptyState();
    } else {
      return _buildStatsGrid(snapshot.data!);
    }
  }

  /// Builds the stats grid when data is available
  Widget _buildStatsGrid(DashboardStats data) {
    return ListView(
      padding: const EdgeInsets.all(15),
      children: [
        const SizedBox(height: 3),
        Text(
          'Hello ${widget.fullname}',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton(
              context,
              icon: Icons.family_restroom,
              label: 'Add Parent',
              onPressed: () => _navigateTo('/new_parent'),
            ),
            _buildActionButton(
              context,
              icon: Icons.school,
              label: 'Add Teacher',
              onPressed: () => _navigateTo('/new_teacher'),
            ),
          ],
        ),
        const SizedBox(height: 25),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.3,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          children: [
            _buildStatCard(
              icon: Icons.family_restroom,
              value: data.totalParents.toString(),
              label: 'Parents',
              color: Colors.blue,
            ),
            _buildStatCard(
              icon: Icons.child_care,
              value: data.totalChildren.toString(),
              label: 'Children',
              color: Colors.green,
            ),
            _buildStatCard(
              icon: Icons.school,
              value: data.totalTeachers.toString(),
              label: 'Teachers',
              color: Colors.orange,
            ),
            _buildStatCard(
              icon: Icons.event_available,
              value: data.totalPickups.toString(),
              label: 'Total Pickups',
              color: Colors.purple,
            ),
          ],
        ),
        _buildPickupLogsSection(),
      ],
    );
  }

  /// Builds the pickup logs section
  Widget _buildPickupLogsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          'Recent Pickups',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        FutureBuilder<List<PickupLog>>(
          future: _pickupLogs,
          builder: (context, logsSnapshot) {
            if (logsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (logsSnapshot.hasError) {
              return _buildErrorState(logsSnapshot.error.toString());
            } else if (!logsSnapshot.hasData || logsSnapshot.data!.isEmpty) {
              return const Center(
                child: Column(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 50),
                    SizedBox(height: 16),
                    Text('No pickup records found'),
                  ],
                ),
              );
            } else {
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: logsSnapshot.data!.length,
                itemBuilder: (context, index) {
                  final log = logsSnapshot.data![index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.check_circle, color: Colors.green),
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
            }
          },
        ),
      ],
    );
  }

  /// Builds an error state widget
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

  /// Formats error messages for display
  String _formatErrorMessage(String error) {
    if (error.contains('401')) return 'Session expired. Please login again.';
    if (error.contains('network')) return 'Network error. Check your connection.';
    return error;
  }

  /// Builds an empty state widget
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

  /// Navigates to a route with slide transition
  void _navigateTo(String route) {
    Navigator.pushNamed(
      context,
      route,
      arguments: widget.token,
    );
  }

  /// Builds an action button with icon and label
  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 24),
      label: Text(label),
    );
  }

  /// Builds a statistic card with icon, value, and label
  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}