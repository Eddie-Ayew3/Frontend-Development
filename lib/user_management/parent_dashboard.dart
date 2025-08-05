import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:safenest/api/New_api.dart';
import 'package:safenest/data_entries/add_child.dart';
import 'package:safenest/data_entries/update_parent.dart';

class ParentDashboard extends StatefulWidget {
  final String userId;
  final String roleId;
  final String email;
  final String fullname;
  final String token;

  const ParentDashboard({
    super.key,
    required this.userId,
    required this.roleId,
    required this.email,
    required this.fullname,
    required this.token,
  });

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _children = [];
  bool _isLoading = false;
  String? _generatedQRCode;
  DateTime? _qrExpiry;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  static const _primaryColor = Color(0xFF5271FF);
  static const _accentColor = Color(0xFF00C9FF);
  static const _whiteColor = Colors.white;
  static const _darkColor = Color(0xFF1A1A2E);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadChildren();

    SchedulerBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadChildren() async {
    setState(() => _isLoading = true);
    try {
      final children = await ApiService.getParentChildren(token: widget.token);
      setState(() {
        _children = children;
        _isLoading = false;
      });
    } on ApiException catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateQRCode(String childId, String childName) async {
    try {
      setState(() => _isLoading = true);
      final qrCode = await ApiService.generateChildQRCode(
        childId: childId,
        token: widget.token,
      );

      setState(() {
        _generatedQRCode = qrCode;
        _qrExpiry = DateTime.now().add(const Duration(minutes: 15));
        _isLoading = false;
      });

      _showQRDialog(childName);
    } on ApiException catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _showQRDialog(String childName) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            color: _whiteColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Pickup Pass',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _darkColor,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_primaryColor, _accentColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _generatedQRCode != null
                          ? Image.memory(
                              base64Decode(_generatedQRCode!.split(',').last),
                              height: 180,
                              width: 180,
                            )
                          : const CircularProgressIndicator(color: _whiteColor),
                      const SizedBox(height: 16),
                      Text(
                        childName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _whiteColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _qrExpiry != null
                            ? 'Valid until: ${DateFormat('MMM d, yyyy - hh:mm a').format(_qrExpiry!)}'
                            : 'Valid until: Unknown',
                        style: const TextStyle(
                          fontSize: 14,
                          color: _whiteColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _whiteColor,
                      foregroundColor: _primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Close',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    try {
      await ApiService.logout();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: ${e.message}'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  void _navigateToAddChild() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            AddChildScreen(
          parentId: widget.roleId,
          token: widget.token,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  void _navigateToUpdateParent() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UpdateParentScreen(
          userId: widget.userId,
          token: widget.token,
        ),
      ),
    );
  }

  Widget _buildChildCard(Map<String, dynamic> child, int index) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, childWidget) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _fadeAnimation.value)),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: childWidget,
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
          onTap: () => _generateQRCode(
            child['childID'].toString(),
            child['fullname'],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Hero(
                  tag: 'child-avatar-${child['childID']}',
                  child: Container(
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
                      child: Text(
                        child['fullname'][0],
                        style: const TextStyle(
                          color: _whiteColor,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        child['fullname'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        child['grade'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.qr_code_scanner, color: _primaryColor),
                  onPressed: () => _generateQRCode(
                    child['childID'].toString(),
                    child['fullname'],
                  ),
                ),
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
        title: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          decoration: BoxDecoration(
            color: _primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'PARENT DASHBOARD',
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
            onPressed: _navigateToUpdateParent,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddChild,
        backgroundColor: _primaryColor,
        foregroundColor: _whiteColor,
        elevation: 4,
        child: const Icon(Icons.add, size: 28),
      ),
      body: RefreshIndicator(
        onRefresh: _loadChildren,
        child: Stack(
          children: [
            CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
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
                        Row(
                          children: [
                            const Text(
                              'My Children',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: _darkColor,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${_children.length} Registered',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isLoading && _children.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: _primaryColor,
                      ),
                    ),
                  )
                else if (_children.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.child_care,
                            size: 60,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No children registered',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _navigateToAddChild,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              foregroundColor: _whiteColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                            ),
                            child: const Text('Add Your First Child'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _buildChildCard(_children[index], index),
                      childCount: _children.length,
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
            if (_isLoading && _children.isNotEmpty)
              const Center(
                child: CircularProgressIndicator(color: _primaryColor),
              ),
          ],
        ),
      ),
    );
  }
}
