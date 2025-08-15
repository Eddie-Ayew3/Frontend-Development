import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:safenest/Api_Service/New_api.dart';
import 'package:safenest/Api_Service/pickup_log.dart';

class PickupLogsView extends StatefulWidget {
  const PickupLogsView({super.key});

  @override
  State<PickupLogsView> createState() => _PickupLogsViewState();
}

class _PickupLogsViewState extends State<PickupLogsView> with SingleTickerProviderStateMixin {
  static const _primaryColor = Color(0xFF5271FF);
  static const _whiteColor = Colors.white;
  static const _darkColor = Color(0xFF1A1A2E);
  static const _morningColor = Color(0xFFFFD700);
  static const _afternoonColor = Color(0xFF4CAF50);

  final List<PickupLog> _pickupLogs = [];
  final List<PickupLog> _filteredLogs = [];
  bool _isLoading = false;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  DateTimeRange? _dateRange;
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
    _loadPickupLogs();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPickupLogs() async {
    setState(() => _isLoading = true);
    try {
      final logs = await ApiService().getPickupLogs();
      if (mounted) {
        setState(() {
          _pickupLogs
            ..clear()
            ..addAll(logs);
          _filteredLogs
            ..clear()
            ..addAll(logs);
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } on ApiException catch (e) {
      if (e.statusCode == 401 && mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
      if (mounted) {
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

  void _filterLogs() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredLogs
        ..clear()
        ..addAll(_pickupLogs.where((log) {
          final matchesSearch = query.isEmpty ||
              log.childName.toLowerCase().contains(query) ||
              log.parentName.toLowerCase().contains(query) ||
              log.grade.toLowerCase().contains(query) ||
              log.verifiedBy.toLowerCase().contains(query);

          final matchesDate = _dateRange == null ||
              (log.verifiedAt.isAfter(_dateRange!.start) &&
                  log.verifiedAt.isBefore(_dateRange!.end.add(const Duration(days: 1))));

          return matchesSearch && matchesDate;
        }));
    });
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() {
        _dateRange = picked;
        _filterLogs();
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _dateRange = null;
      _filteredLogs
        ..clear()
        ..addAll(_pickupLogs);
    });
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  String _mapErrorToMessage(ApiException e) {
    if (e.statusCode == 400) return 'Invalid request. Please try again.';
    if (e.statusCode == 401) return 'Session expired. Please login again.';
    if (e.statusCode == 404) return 'No pickup logs found.';
    if (e.message.contains('network')) return 'Network error. Check your connection.';
    return e.message;
  }

  Widget _buildPickupLogCard(PickupLog log) {
    final hour = log.verifiedAt.hour;
    final isMorning = hour < 12;
    final color = isMorning ? _morningColor : _afternoonColor;
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
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: color.withOpacity(0.3), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
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
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
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
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Parent: ${log.parentName}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.verified_user, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Verified by: ${log.verifiedBy}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM d, hh:mm a').format(log.verifiedAt),
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.school, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Grade: ${log.grade}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
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
            onPressed: _loadPickupLogs,
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

  Widget _buildDateRangeChip() {
    if (_dateRange == null) return const SizedBox.shrink();

    return Chip(
      label: Text(
        '${DateFormat('MMM d').format(_dateRange!.start)} - ${DateFormat('MMM d').format(_dateRange!.end)}',
      ),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: () {
        setState(() {
          _dateRange = null;
          _filterLogs();
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final sortedLogs = List<PickupLog>.from(_filteredLogs)
      ..sort((a, b) => b.verifiedAt.compareTo(a.verifiedAt));

    return RefreshIndicator(
      onRefresh: _loadPickupLogs,
      color: _primaryColor,
      child: Stack(
        children: [
          CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search pickups...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    _searchController.clear();
                                    _filterLogs();
                                  },
                                )
                              : null,
                        ),
                        onChanged: (_) => _filterLogs(),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.filter_alt),
                            label: const Text('Date Range'),
                            onPressed: () => _selectDateRange(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              foregroundColor: _whiteColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh'),
                            onPressed: _isLoading ? null : _loadPickupLogs,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              foregroundColor: _whiteColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_dateRange != null) _buildDateRangeChip(),
                      const SizedBox(height: 8),
                      Text(
                        'Recent Pickup Activity',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _darkColor.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Showing ${sortedLogs.length} of ${_pickupLogs.length} records',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (_dateRange != null || _searchController.text.isNotEmpty)
                        TextButton(
                          onPressed: _clearFilters,
                          child: const Text('Clear filters'),
                        ),
                    ],
                  ),
                ),
              ),
              if (_errorMessage != null)
                SliverFillRemaining(child: _buildErrorState(_errorMessage!))
              else if (_isLoading && sortedLogs.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: _primaryColor)),
                )
              else if (sortedLogs.isEmpty)
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
                    (context, index) => _buildPickupLogCard(sortedLogs[index]),
                    childCount: sortedLogs.length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          if (_isLoading && sortedLogs.isNotEmpty)
            const Center(
              child: CircularProgressIndicator(color: _primaryColor),
            ),
        ],
      ),
    );
  }
}

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

class _ParentDashboardState extends State<ParentDashboard> with SingleTickerProviderStateMixin {
  static const _primaryColor = Color(0xFF5271FF);
  static const _accentColor = Color(0xFF00C9FF);
  static const _whiteColor = Colors.white;
  static const _darkColor = Color(0xFF1A1A2E);

  final List<Map<String, dynamic>> _children = [];
  bool _isLoading = false;
  String? _generatedQRCode;
  DateTime? _qrExpiry;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String? _errorMessage;

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
    setState(() => _isLoading = true);
    try {
      final children = await ApiService().getParentChildren();
      if (mounted) {
        setState(() {
          _children
            ..clear()
            ..addAll(children);
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } on ApiException catch (e) {
      if (e.statusCode == 401 && mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load data: ${e.message}';
        });
        _showErrorSnackbar('Failed to load data: ${e.message}');
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

  Future<void> _generateQRCode(String childId, String childName) async {
    try {
      setState(() => _isLoading = true);
      final qrCode = await ApiService().generateChildQRCode(
        childId: childId,
        token: widget.token,
      );
      if (mounted) {
        setState(() {
          _generatedQRCode = qrCode;
          _qrExpiry = DateTime.now().add(const Duration(minutes: 15));
          _isLoading = false;
        });
        _showQRDialog(childName);
      }
    } on ApiException catch (e) {
      if (e.statusCode == 401 && mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackbar('QR generation failed: ${e.message}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackbar('QR generation failed');
      }
    }
  }

  void _showQRDialog(String childName) {
    if (_generatedQRCode == null || _qrExpiry == null) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
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
                  'Pickup Pass for $childName',
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
                      Image.memory(
                        base64Decode(_generatedQRCode!.split(',').last),
                        height: 180,
                        width: 180,
                      ),
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
                        'Valid until: ${DateFormat('MMM d, yyyy - hh:mm a').format(_qrExpiry!)}',
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

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_formatErrorMessage(message)),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 5),
      ),
    );
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

  void _navigateToAddChild() {
    Navigator.pushNamed(
      context,
      '/new_child',
      arguments: {
        'parentId': widget.roleId,
        'token': widget.token,
      },
    );
  }

  void _navigateToUpdateParent() {
    Navigator.pushNamed(
      context,
      '/update_parent',
      arguments: {
        'roleId': widget.roleId,
        'token': widget.token,
      },
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
          onTap: () async {
            await _generateQRCode(
              child['id'],
              child['fullname'] ?? '${child['firstName']} ${child['lastName']}',
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Hero(
                  tag: 'child-avatar-${child['id']}',
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
                        (child['fullname'] ?? '${child['firstName']} ${child['lastName']}')[0],
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
                        child['fullname'] ?? '${child['firstName']} ${child['lastName']}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        child['grade'] ?? '',
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
                  onPressed: () async {
                    await _generateQRCode(
                      child['id'],
                      child['fullname'] ?? '${child['firstName']} ${child['lastName']}',
                    );
                  },
                ),
              ],
            ),
          ),
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
          Text(
            'Error loading data\n${_formatErrorMessage(error)}',
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

  Widget _buildEmptyState() {
    return Center(
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
    );
  }

  String _formatErrorMessage(String error) {
    if (error.contains('401')) return 'Session expired. Please login again.';
    if (error.contains('network')) return 'Network error. Check your connection.';
    return error;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.settings),
          onPressed: _navigateToUpdateParent,
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
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddChild,
        backgroundColor: _primaryColor,
        foregroundColor: _whiteColor,
        elevation: 4,
        child: const Icon(Icons.add, size: 28),
      ),
      body: DefaultTabController(
        length: 2,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                  child: Container(
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
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
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
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    indicatorColor: _primaryColor,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorWeight: 3,
                    labelColor: _darkColor,
                    unselectedLabelColor: Colors.grey[600],
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                    tabs: const [
                      Tab(text: 'Children'),
                      Tab(text: 'Pickups'),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              RefreshIndicator(
                onRefresh: _loadData,
                color: _primaryColor,
                child: Stack(
                  children: [
                    CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        if (_errorMessage != null)
                          SliverFillRemaining(child: _buildErrorState(_errorMessage!))
                        else if (_isLoading && _children.isEmpty)
                          const SliverFillRemaining(
                            child: Center(child: CircularProgressIndicator(color: _primaryColor)),
                          )
                        else if (_children.isEmpty)
                          SliverFillRemaining(child: _buildEmptyState())
                        else
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => _buildChildCard(_children[index], index),
                              childCount: _children.length,
                            ),
                          ),
                        const SliverToBoxAdapter(child: SizedBox(height: 100)),
                      ],
                    ),
                    if (_isLoading && _children.isNotEmpty)
                      const Center(child: CircularProgressIndicator(color: _primaryColor)),
                  ],
                ),
              ),
              const PickupLogsView(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverAppBarDelegate(this.tabBar);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.grey[50],
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}