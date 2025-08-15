import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:safenest/Api_Service/New_api.dart';
import 'package:safenest/Api_Service/pickup_log.dart';

class PickupLogsPage extends StatefulWidget {
  final String userId;
  final String token;
  final String roleId;

  const PickupLogsPage({
    super.key,
    required this.userId,
    required this.token,
    required this.roleId,
  });

  @override
  State<PickupLogsPage> createState() => _PickupLogsPageState();
}

class _PickupLogsPageState extends State<PickupLogsPage>
    with SingleTickerProviderStateMixin {
  static const _primaryColor = Color(0xFF5271FF);
  static const _whiteColor = Colors.white;
  static const _darkColor = Color(0xFF1A1A2E);
  static const _morningColor = Color(0xFFFFD700);
  static const _afternoonColor = Color(0xFF4CAF50);

  List<PickupLog> _pickupLogs = [];
  List<PickupLog> _filteredLogs = [];
  bool _isLoading = false;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _searchController = TextEditingController();
  DateTimeRange? _dateRange;
  bool _isSearching = false;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
          _pickupLogs = logs;
          _filteredLogs = logs;
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
      _filteredLogs = _pickupLogs.where((log) {
        final matchesSearch = query.isEmpty ||
            log.childName.toLowerCase().contains(query) ||
            log.parentName.toLowerCase().contains(query) ||
            log.grade.toLowerCase().contains(query) ||
            log.verifiedBy.toLowerCase().contains(query);

        final matchesDate = _dateRange == null ||
            (log.verifiedAt.isAfter(_dateRange!.start) &&
                log.verifiedAt.isBefore(_dateRange!.end.add(const Duration(days: 1))));

        return matchesSearch && matchesDate;
      }).toList();
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
      _filteredLogs = _pickupLogs;
      _isSearching = false;
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

  Widget _buildPickupLogCard(PickupLog log, int index) {
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
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Chip(
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sortedLogs = List<PickupLog>.from(_filteredLogs)
      ..sort((a, b) => b.verifiedAt.compareTo(a.verifiedAt));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search pickups...',
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _isSearching = false;
                        _searchController.clear();
                        _filterLogs();
                      });
                    },
                  ),
                ),
                onChanged: (_) => _filterLogs(),
              )
            : const Text('Pickup Logs'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: _darkColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadPickupLogs,
            tooltip: 'Refresh',
          ),
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.filter_alt),
              onPressed: () => _selectDateRange(context),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPickupLogs,
        color: _primaryColor,
        child: Stack(
          children: [
            CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      if (_dateRange != null) _buildDateRangeChip(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Column(
                          children: [
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
                    ],
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
                      (context, index) => _buildPickupLogCard(sortedLogs[index], index),
                      childCount: sortedLogs.length,
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
            if (_isLoading && sortedLogs.isNotEmpty)
              const Center(
                child: CircularProgressIndicator(color: _primaryColor)),
          ],
        ),
      ),
    );
  }
}