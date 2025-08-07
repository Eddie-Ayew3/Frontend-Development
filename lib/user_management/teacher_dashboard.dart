import 'package:flutter/material.dart';
import 'package:safenest/api/New_api.dart';
import 'package:safenest/data_entries/qr_scanner_screen.dart';
import 'package:safenest/data_entries/update_teacher.dart';

/// Teacher dashboard screen with action buttons for school operations
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
  // Constants for consistent styling
  static const _primaryColor = Color(0xFF5271FF);
  static const _accentColor = Color(0xFF00C9FF);
  static const _whiteColor = Colors.white;
  static const _darkColor = Color(0xFF1A1A2E);

  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize animations
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

    // Start animation after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Handles user logout
  Future<void> _logout() async {
    try {
      setState(() => _isLoading = true);
      await ApiService.logout();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    } on ApiException catch (e) {
      if (mounted) {
        _showErrorSnackbar('Logout failed: ${e.message}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Shows error message in a snackbar
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  /// Navigates to update teacher profile screen
  void _navigateToUpdateTeacher() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UpdateTeacherScreen(
          userId: widget.userId,
          token: widget.token,
        ),
      ),
    );
  }

  /// Navigates to QR scanner screen
  void _navigateToQRScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QRScannerScreen(token: widget.token),
      ),
    );
  }

  /// Builds an action button with animation
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
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_primaryColor, _accentColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(icon, color: _whiteColor, size: 28),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap to ${label.toLowerCase()}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: _primaryColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          decoration: BoxDecoration(
            color: _primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'TEACHER DASHBOARD',
            style: TextStyle(
              color: _primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: _darkColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: _navigateToUpdateTeacher,
            tooltip: 'Settings',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Stack(
        children: [
          CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
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
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
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
                  _buildActionButton(
                    Icons.qr_code_scanner,
                    'Scan QR Code',
                    _navigateToQRScanner,
                  ),
                  _buildActionButton(
                    Icons.class_outlined,
                    'View Classes',
                    () {
                      // TODO: Implement view classes functionality
                      _showComingSoonSnackbar();
                    },
                  ),
                  _buildActionButton(
                    Icons.people_outline,
                    'Student List',
                    () {
                      // TODO: Implement student list functionality
                      _showComingSoonSnackbar();
                    },
                  ),
                ]),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: _primaryColor),
            ),
        ],
      ),
    );
  }

  /// Shows a "coming soon" snackbar for unimplemented features
  void _showComingSoonSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This feature is coming soon!'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }
}