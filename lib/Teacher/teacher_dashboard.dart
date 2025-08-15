import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:safenest/Api_Service/New_api.dart';
import 'package:safenest/Api_Service/pickup_log.dart';
import 'package:safenest/Teacher/qr_scanner_screen.dart';
import 'package:safenest/Teacher/studentList.dart';
import 'package:safenest/Teacher/teacher_logs.dart';
import 'package:safenest/Teacher/update_teacher.dart';

class TeacherDashboard extends StatefulWidget {
  final String userId;
  final String roleId;
  final String email;
  final String fullname;
  final String token;

  const TeacherDashboard({
    super.key,
    required this.userId,
    required this.roleId,
    required this.email,
    required this.fullname,
    required this.token,
  });

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard>
    with SingleTickerProviderStateMixin {
  static const _primaryColor = Color(0xFF5271FF);
  static const _whiteColor = Colors.white;
  static const _darkColor = Color(0xFF1A1A2E);

  bool _isLoading = false;
  List<PickupLog> _pickupLogs = [];
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutQuart,
      ),
    );

    _loadData();

    SchedulerBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final logs = await ApiService().getPickupLogs();
      if (mounted) {
        setState(() {
          _pickupLogs = logs;
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (e.statusCode == 401 && mounted) {
        _showErrorSnackbar('Session expired. Please login again.');
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      } else if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = _mapErrorToMessage(e);
        });
        _showErrorSnackbar(_mapErrorToMessage(e));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'An unexpected error occurred';
        });
        _showErrorSnackbar('An unexpected error occurred');
      }
    }
  }

  Future<void> _navigateToQRScanner() async {
    try {
      setState(() => _isLoading = true);
      final token = await ApiService.getAuthToken();
      if (token == null && mounted) {
        _showErrorSnackbar('Please log in to scan QR codes');
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        return;
      }
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QRScannerScreen(token: widget.token),
          ),
        );
        _loadData();
      }
    } catch (e) {
      _showErrorSnackbar('Failed to open scanner');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  Future<void> _navigateToStudentList() async {
    try {
      setState(() => _isLoading = true);
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TeacherClassStudents(
            userId: widget.userId,
            roleId: widget.roleId,
            token: widget.token,
          ),
        ),
      );
    } catch (e) {
      _showErrorSnackbar('Failed to open student list');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _navigateToPickupLogs() async {
    try {
      setState(() => _isLoading = true);
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PickupLogsPage(
            userId: widget.userId,
            roleId: widget.roleId,
            token: widget.token,
          ),
        ),
      );
      // Refresh data after returning from logs page
      _loadData();
    } catch (e) {
      _showErrorSnackbar('Failed to open pickup logs');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }



Future<void> _navigateToUpdateProfile() async {
  try {
    // Add debug prints to verify data
    debugPrint('Navigating with userId: ${widget.userId}');
    debugPrint('Using token: ${widget.token.substring(0, 10)}...');

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UpdateTeacherScreen(
          roleId: widget.roleId,
          token: widget.token,
        ),
      ),
    );

    if (result == true && mounted) {
      _showSuccessSnackbar('Profile updated successfully');
      // Refresh the dashboard data
      await _loadData();
    }
  } catch (e) {
    if (mounted) {
      _showErrorSnackbar('Failed to update profile: ${e.toString()}');
    }
  }
}

  Future<void> _logout() async {
    try {
      setState(() => _isLoading = true);
      await ApiService().logout();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } on ApiException catch (e) {
      if (mounted) {
        _showErrorSnackbar('Logout failed: ${e.message}');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Logout failed');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      ),
    );
  }

  String _mapErrorToMessage(ApiException e) {
    if (e.statusCode == 400) return 'Invalid request. Please try again.';
    if (e.statusCode == 401) return 'Session expired. Please login again.';
    if (e.statusCode == 404) return 'Data not found.';
    if (e.message.contains('network')) return 'Network error. Please check your connection.';
    return 'Error: ${e.message}';
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onPressed) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _fadeAnimation.value)),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _isLoading ? null : onPressed,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      // ignore: deprecated_member_use
                      color: _primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: _primaryColor, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey[400]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPickupLogCard(PickupLog log, int index) {
    final hour = log.verifiedAt.hour;
    final isMorning = hour < 12;
    final color = isMorning ? Color(0xFFFFD700) : Color(0xFF4CAF50);
    final period = isMorning ? 'Morning' : 'Afternoon';

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _fadeAnimation.value)),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: child,
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          // ignore: deprecated_member_use
          side: BorderSide(color: color.withOpacity(0.3), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    log.childName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      // ignore: deprecated_member_use
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      // ignore: deprecated_member_use
                      border: Border.all(color: color.withOpacity(0.5)),
                    ),
                    child: Text(
                      period,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Parent: ${log.parentName}',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                'Verified by: ${log.verifiedBy}',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('MMM d, hh:mm a').format(log.verifiedAt),
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  Text(
                    'Grade: ${log.grade}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 50),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: _whiteColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.settings),
          onPressed: _navigateToUpdateProfile,
          tooltip: 'Settings',
        ),
        title: Image.asset(
          'assets/safenest.png',
          height: 50,
          fit: BoxFit.contain,
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: _darkColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: _primaryColor,
        child: Stack(
          children: [
            CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 3),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            // ignore: deprecated_member_use
                            color: _primaryColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Hello, ${widget.fullname}!',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: _darkColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                widget.email,
                                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          'Teacher Actions',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _darkColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ), 
                SliverList(
                  delegate: SliverChildListDelegate([
                    _buildActionButton(Icons.qr_code_scanner, 'Scan QR Code', _navigateToQRScanner),
                    _buildActionButton(Icons.people_outline, 'Student List', _navigateToStudentList),
                    _buildActionButton(Icons.list_alt, 'Pickup Logs', _navigateToPickupLogs),
                  ]),
                ),
                if (_errorMessage != null)
                  SliverFillRemaining(child: _buildErrorState(_errorMessage!))
                else if (_isLoading && _pickupLogs.isEmpty)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator(color: _primaryColor)),
                  )
                else if (_pickupLogs.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'No pickup logs available',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildPickupLogCard(_pickupLogs[index], index),
                      childCount: _pickupLogs.length,
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
            if (_isLoading && _pickupLogs.isNotEmpty)
              const Center(
                child: CircularProgressIndicator(color: _primaryColor),
              ),
          ],
        ),
      ),
    );
  }
}