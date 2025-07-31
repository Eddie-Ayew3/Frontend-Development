// Add your imports as before
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  late List<Map<String, dynamic>> _stats;
  late List<dynamic> _pickupLogs;
  String _adminName = 'Admin';
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final adminProfile = {'fullName': 'John Doe'};
      _stats = _fetchStats();
      _pickupLogs = _fetchPickupLogs();
      if (mounted) {
        setState(() {
          _adminName = adminProfile['fullName'] ?? 'Admin';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load data';
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to load data'),
            action: SnackBarAction(label: 'Retry', onPressed: _loadData),
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> _fetchStats() {
    return [
      {'label': 'Total Parents', 'count': 150, 'icon': Icons.person_rounded},
      {'label': 'Total Teachers', 'count': 30, 'icon': Icons.school_rounded},
      {'label': 'Total Children', 'count': 300, 'icon': Icons.child_care_rounded},
      {'label': 'Pickups Today', 'count': 25, 'icon': Icons.directions_car_rounded},
    ];
  }

  List<dynamic> _fetchPickupLogs() {
    return [
      {
        'fullName': 'Emma Smith',
        'parentName': 'Jane Smith',
        'verifiedAt': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      },
      {
        'fullName': 'Liam Johnson',
        'parentName': 'Mark Johnson',
        'verifiedAt': DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
      },
      {
        'fullName': 'Olivia Brown',
        'parentName': 'Sarah Brown',
        'verifiedAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      },
    ];
  }

  Future<void> _handleRefresh() async {
    await _loadData();
  }

  Future<void> _logout(BuildContext context) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (Route<dynamic> route) => false,
      );
    }
  }

  Future<void> _createParent() async {
    final result = await Navigator.pushNamed(context, '/new_parent');
    if (result == true && mounted) {
      _handleRefresh();
    }
  }

  Future<void> _createTeacher() async {
    final result = await Navigator.pushNamed(context, '/new_teacher');
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
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'refresh') {
                _handleRefresh();
              } 
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'refresh', child: Text('Refresh Data')),
            ],
          ),
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              child: Column(
                children: [
                  Expanded(child: Container(
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                    Text(
                      'Welcome, $_adminName 👋',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Today is $formattedDate',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _createParent,
                            icon: const Icon(Icons.person_add_alt_1_rounded),
                            label: const Text("Add Parent"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5271FF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _createTeacher,
                            icon: const Icon(Icons.school_rounded),
                            label: const Text("Add Teacher"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5271FF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'System Stats',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _stats.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.1, // adjusted
                      ),
                      itemBuilder: (context, index) => _buildStatCard(
                        label: _stats[index]['label'],
                        count: _stats[index]['count'].toString(),
                        icon: _stats[index]['icon'],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Recent Pickups',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _pickupLogs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final log = _pickupLogs[index];
                        final childName = log['fullName'] ?? 'Unknown Child';
                        final parentName = log['parentName'] ?? 'Unknown Parent';
                        final dateTime = DateTime.tryParse(log['verifiedAt'] ?? '');
                        final formattedTime = dateTime != null
                            ? DateFormat('MMM d, h:mm a').format(dateTime)
                            : 'Unknown time';
                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.access_time_rounded, color: Color(0xFF5271FF)),
                            title: Text('$childName picked up by $parentName'),
                            subtitle: Text(formattedTime),
                            trailing: const Icon(Icons.check_circle_rounded, color: Colors.green),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            const ModalBarrier(dismissible: false, color: Colors.black54),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        ],
      ),
      ),
    ),
        ],
    ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String count,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF5271FF).withOpacity(0.1),
            child: Icon(icon, color: const Color(0xFF5271FF)),
          ),
          const SizedBox(height: 12),
          Text(
            count,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5271FF),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13, // slightly smaller
              color: Colors.black87,
              overflow: TextOverflow.ellipsis,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}
