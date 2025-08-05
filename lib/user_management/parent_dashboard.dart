/*import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:safenest/api/New_Api.dart';

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

class _ParentDashboardState extends State<ParentDashboard> {
  List<Map<String, dynamic>> _children = [];
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _parentData;
  String? _generatedQRCode;

  // Colors
  static const _primaryColor = Color(0xFF5271FF);
  static const _whiteColor = Colors.white;
  static const _greyColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final results = await Future.wait([
        ApiService.safeApiCall(() => ApiService.getParentProfile(userId: widget.userId)),
        ApiService.safeApiCall(() => ApiService.g
      ]);

      if (mounted) {
        setState(() {
          _parentData = results[0] as Map<String, dynamic>;
          _children = (results[1] as List).map((child) => {
            'id': child['ChildID'].toString(),
            'fullName': child['Fullname'] as String? ?? 'Unknown',
            'grade': child['Grade'] as String? ?? 'No Grade',
          }).toList().cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _mapErrorToMessage(e);
          _isLoading = false;
        });
        _showErrorSnackbar('Failed to load data: $_errorMessage', _loadData);
      }
    }
  }

  String _mapErrorToMessage(ApiException e) {
    switch (e.statusCode) {
      case 401: return 'Session expired. Please log in again';
      case 403: return 'You don\'t have permission';
      case 404: return 'Resource not found';
      case 429: return 'Too many requests, please try again later';
      default: return e.message;
    }
  }

  void _showErrorSnackbar(String message, VoidCallback? retryAction) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: retryAction != null 
          ? SnackBarAction(label: 'Retry', onPressed: retryAction)
          : null,
      ),
    );
  }

  Future<void> _handleRefresh() async => _loadData();

  Future<void> _logout() async {
    setState(() => _isLoading = true);
    try {
      await ApiService.logout();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (Route<dynamic> route) => false,
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _mapErrorToMessage(e);
          _isLoading = false;
        });
        _showErrorSnackbar('Logout failed: $_errorMessage', null);
      }
    }
  }

  void _navigateToProfile() {
    Navigator.pushNamed(context, '/parent_profile', arguments: widget.userId);
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

  Future<void> _generateQRCode(String childId, String childName) async {
    try {
      setState(() => _isLoading = true);
      final token = await ApiService.getAuthToken();
      if (token == null) throw ApiException('No authentication token found', statusCode: 401);

      final qrCode = await ApiService.safeApiCall(() => ApiService.generateQRCode(childId, token));
      if (mounted) {
        setState(() {
          _generatedQRCode = qrCode;
          _isLoading = false;
        });
        _showQRCodeDialog(childName);
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _mapErrorToMessage(e);
          _isLoading = false;
        });
        _showErrorSnackbar('Failed to generate QR code: $_errorMessage', null);
      }
    }
  }

  Future<void> _viewPickupStatus(String childId, String childName) async {
    await Navigator.pushNamed(context, '/pickup_status', arguments: {
      'childId': childId,
      'childName': childName,
    });
  }

  void _showQRCodeDialog(String childName) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Pickup Pass for $childName',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _primaryColor, width: 2),
                ),
                child: Column(
                  children: [
                    if (_generatedQRCode != null)
                      Image.memory(
                        base64Decode(_generatedQRCode!.split(',').last),
                        height: 200,
                        width: 200,
                      )
                    else
                      const Icon(Icons.qr_code_2, size: 120, color: _primaryColor),
                    const SizedBox(height: 8),
                    Text(
                      childName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM d, yyyy').format(DateTime.now()),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Show this digital pass at the school gate',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Close',
                    style: TextStyle(color: _whiteColor),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChildCard(Map<String, dynamic> child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
        leading: CircleAvatar(
          backgroundColor: _primaryColor.withOpacity(0.1),
          child: Text(
            child['fullName']?[0] ?? '?',
            style: const TextStyle(
              color: _primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          child['fullName'] ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(child['grade'] ?? 'No grade'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.qr_code_2, color: _primaryColor),
              onPressed: _isLoading
                  ? null
                  : () => _generateQRCode(child['id'].toString(), child['fullName'] ?? 'Child'),
            ),
            IconButton(
              icon: const Icon(Icons.info, color: _primaryColor),
              onPressed: _isLoading
                  ? null
                  : () => _viewPickupStatus(child['id'].toString(), child['fullName'] ?? 'Child'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildrenList() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_children.isEmpty) {
      return Column(
        children: [
          const Center(
            child: Text('No children found', style: TextStyle(color: _greyColor)),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _navigateToAddChild,
            child: const Text('Add Child'),
          ),
        ],
      );
    }
    return Column(
      children: [
        ..._children.map(_buildChildCard).toList(),
        ElevatedButton(
          onPressed: _navigateToAddChild,
          child: const Text('Add Another Child'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat.yMMMMd().add_jm().format(DateTime.now());

    return Scaffold(
      backgroundColor: _primaryColor,
      appBar: AppBar(
        title: Text('Parent Dashboard - ${widget.roleId}'),
        centerTitle: true,
        backgroundColor: _primaryColor,
        foregroundColor: _whiteColor,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _navigateToProfile,
            icon: const CircleAvatar(
              radius: 16,
              backgroundColor: _whiteColor,
              child: Icon(Icons.person, size: 18, color: _primaryColor),
            ),
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: _whiteColor),
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _handleRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  if (_errorMessage != null)
                    _buildErrorBanner(_errorMessage!),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: _whiteColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '📅 $formattedDate',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Hello, ${widget.fullname}!',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Email: ${widget.email}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        _buildMainContentCard(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading) ...[
            const ModalBarrier(dismissible: false, color: Colors.black54),
            const Center(child: CircularProgressIndicator(color: _whiteColor)),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Padding(
      padding: const EdgeInsets.all(16),
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
                  message,
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
    );
  }

  Widget _buildMainContentCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Generate Digital Pickup Pass',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Select a child to generate their one-time pickup QR code',
            style: TextStyle(
              fontSize: 14,
              color: _greyColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildChildrenList(),
        ],
      ),
    );
  }
}*/