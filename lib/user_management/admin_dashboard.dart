import 'package:flutter/material.dart';
import 'package:safenest/api/New_api.dart';

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

  @override
  void initState() {
    super.initState();
    _dashboardStats = _fetchDashboardStats();
  }

  Future<DashboardStats> _fetchDashboardStats() async {
    try {
      final response = await ApiService.getAdminDashboard(widget.token);
      return DashboardStats.fromJson(response);
    } catch (e) {
      throw ApiException('Failed to load dashboard stats: $e');
    }
  }

  Future<void> _refreshDashboard() async {
    setState(() {
      _dashboardStats = _fetchDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 18),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('ADMINISTRATOR',
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
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshDashboard,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              const SizedBox(height:3),
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
                    onPressed: () => Navigator.pushNamed(context, '/new_parent', arguments: widget.token),
                  ),
                  _buildActionButton(
                    context,
                    icon: Icons.school,
                    label: 'Add Teacher',
                    onPressed: () => Navigator.pushNamed(context, '/new_teacher', arguments: widget.token),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              FutureBuilder<DashboardStats>(
                future: _dashboardStats,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    final error = snapshot.error is ApiException
                        ? (snapshot.error as ApiException).message
                        : snapshot.error.toString();
                    return Column(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 50),
                        const SizedBox(height: 10),
                        Text(
                          'Error: $error',
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _refreshDashboard,
                          child: const Text('Retry'),
                        ),
                      ],
                    );
                  } else if (!snapshot.hasData) {
                    return const Text('No data available');
                  }

                  final stats = snapshot.data!;
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 1.3,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    children: [
                      _buildStatCard(
                        icon: Icons.family_restroom,
                        value: stats.totalParents.toString(),
                        label: 'Parents',
                        color: Colors.blue,
                      ),
                      _buildStatCard(
                        icon: Icons.child_care,
                        value: stats.totalChildren.toString(),
                        label: 'Children',
                        color: Colors.green,
                      ),
                      _buildStatCard(
                        icon: Icons.school,
                        value: stats.totalTeachers.toString(),
                        label: 'Teachers',
                        color: Colors.orange,
                      ),
                      _buildStatCard(
                        icon: Icons.event_available,
                        value: stats.totalPickups.toString(),
                        label: 'Total Pickups',
                        color: Colors.purple,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
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
        padding: const EdgeInsets.symmetric(vertical:10, horizontal: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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

  void _handleLogout(BuildContext context) async {
    try {
      await ApiService.logout();
      if (!context.mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }
}