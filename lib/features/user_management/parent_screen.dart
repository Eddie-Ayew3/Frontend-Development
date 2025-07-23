// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:safenest/api_services/file.dart';
import 'package:safenest/features/dashboard/update_sections/update_parent.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  late Future<List<dynamic>> _childrenFuture;
  late Future<List<dynamic>> _pickupLogsFuture;
  String _parentName = 'Parent';
  String? _errorMessage;
  bool _isLoadingQR = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _childrenFuture = _fetchChildren();
      _pickupLogsFuture = _fetchPickupLogs();
    });
    try {
      final parentProfile = await ApiService.getParentProfile();
      if (mounted) {
        setState(() {
          _parentName = parentProfile['fullName'] ?? 'Parent';
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _mapErrorToMessage(e);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load profile: ${e.toString()}';
        });
      }
    }
  }

  Future<List<dynamic>> _fetchChildren() async {
    try {
      final response = await ApiService.safeApiCall(() => ApiService.getChildren());
      return List<Map<String, dynamic>>.from(response['children'] ?? []);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load children';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load children')),
        );
      }
      return [];
    }
  }

  Future<List<dynamic>> _fetchPickupLogs() async {
    try {
      return await ApiService.safeApiCall(() => ApiService.getPickupLogs());
    } on ApiException catch (e) {
      throw ApiException('Failed to load pickup logs: ${e.message}', statusCode: e.statusCode);
    } catch (e) {
      throw ApiException('Failed to load pickup logs: ${e.toString()}');
    }
  }

  Future<void> _handleRefresh() async {
    await _loadData();
  }

  Future<void> _logout(BuildContext context) async {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await ApiService.logout();
      if (mounted) {
        Navigator.pop(context);
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (Route<dynamic> route) => false,
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: ${_mapErrorToMessage(e)}')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _generateAndShowQRCode(BuildContext context, String childId, String childName) async {
    if (!mounted || _isLoadingQR) return;

    setState(() {
      _isLoadingQR = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.safeApiCall(
        () => ApiService.generateQRCode(int.parse(childId)),
      );

      final base64Image = response['qrCode'];
      if (base64Image == null || base64Image.isEmpty) {
        throw ApiException('Invalid QR code data received');
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('QR Code for $childName'),
            content: QRDisplayWidget(
              base64Image: base64Image,
              onRetry: () => _generateAndShowQRCode(context, childId, childName),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/parent-dashboard'),
                child: const Text('Back to Dashboard'),
              ),
            ],
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _mapErrorToMessage(e);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate QR code: ${_mapErrorToMessage(e)}')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An unexpected error occurred: ${e.toString()}';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingQR = false;
        });
      }
    }
  }

  String _mapErrorToMessage(ApiException e) {
    switch (e.message) {
      case 'Invalid child ID':
        return 'The provided child ID is invalid';
      case 'Network error':
        return 'Please check your internet connection';
      case 'Unauthorized':
        return 'Please log in again';
      case 'Child not found or not associated with this parent.':
        return 'The selected child is not associated with you';
      default:
        return e.message;
    }
  }

  void _navigateWithFade(Widget page) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
      ),
    );
  }

  Future<void> updateParent() async {
    final result = await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const UpdateParentScreen(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
      ),
    );
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
        title: const Text('Parent Dashboard'),
        centerTitle: true,
        backgroundColor: const Color(0xFF5271FF),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'refresh') {
                _handleRefresh();
              } else if (value == 'update_profile') {
                updateParent(); // Now uses fade transition
              }
            },
            itemBuilder: (BuildContext context) => const [
              PopupMenuItem(value: 'refresh', child: Text('Refresh Data')),
              PopupMenuItem(value: 'update_profile', child: Text('Update Profile')),
            ],
          ),
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          child: Column(
            children: [
              const SizedBox(height: 3),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: IntrinsicHeight(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  '📅 $formattedDate',
                                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Hello, $_parentName!',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (_errorMessage != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
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
                                                _errorMessage!,
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
                                  ),
                                const Text(
                                  'Recent Pickups',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 8),
                                FutureBuilder<List<dynamic>>(
                                  future: _pickupLogsFuture,
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return const Center(child: CircularProgressIndicator());
                                    } else if (snapshot.hasError) {
                                      final errorMessage = snapshot.error is ApiException
                                          ? _mapErrorToMessage(snapshot.error as ApiException)
                                          : 'Error: ${snapshot.error.toString()}';
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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
                                                    errorMessage,
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
                                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                      return const Center(child: Text('No pickup logs found'));
                                    }

                                    return ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: snapshot.data!.length,
                                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                                      itemBuilder: (context, index) {
                                        final log = snapshot.data![index];
                                        final childName = log['fullName'] ?? 'Unknown Child';
                                        final parentName = log['parentName'] ?? 'Unknown Parent';
                                        final dateTime = DateTime.tryParse(log['verifiedAt'] ?? '');
                                        final formattedTime = dateTime != null
                                            ? DateFormat('MMM d, h:mm a').format(dateTime)
                                            : 'Unknown time';
                                        return Card(
                                          child: ListTile(
                                            title: Text('$childName picked up by $parentName'),
                                            subtitle: Text(formattedTime),
                                            trailing: const Icon(
                                              Icons.check_circle,
                                              color: Colors.green,
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Generate Pickup QR Code',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                AbsorbPointer(
                                  absorbing: _isLoadingQR,
                                  child: Opacity(
                                    opacity: _isLoadingQR ? 0.6 : 1.0,
                                    child: FutureBuilder<List<dynamic>>(
                                      future: _childrenFuture,
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return const Center(child: CircularProgressIndicator());
                                        } else if (snapshot.hasError) {
                                          final errorMessage = snapshot.error is ApiException
                                              ? _mapErrorToMessage(snapshot.error as ApiException)
                                              : 'Error: ${snapshot.error.toString()}';
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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
                                                        errorMessage,
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
                                        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                          return const Center(child: Text('No children found'));
                                        }

                                        return ListView.separated(
                                          shrinkWrap: true,
                                          physics: const NeverScrollableScrollPhysics(),
                                          itemCount: snapshot.data!.length,
                                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                                          itemBuilder: (context, index) {
                                            final child = snapshot.data![index];
                                            final childId = child['id']?.toString() ?? 'unknown';
                                            final childName = child['fullName'] ?? 'Unknown Child';
                                            final childGrade = child['grade'] ?? 'Unknown Grade';
                                            return Card(
                                              child: ListTile(
                                                title: Text(childName),
                                                subtitle: Text(childGrade),
                                                trailing: _isLoadingQR
                                                    ? const CircularProgressIndicator()
                                                    : ElevatedButton(
                                                        onPressed: () => _generateAndShowQRCode(context, childId, childName),
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: const Color(0xFF5271FF),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(16),
                                                          ),
                                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                                        ),
                                                        child: const Text(
                                                          'Generate QR Code',
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            fontWeight: FontWeight.w600,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QRDisplayWidget extends StatelessWidget {
  final String base64Image;
  final VoidCallback? onRetry;

  const QRDisplayWidget({super.key, required this.base64Image, this.onRetry});

  @override
  Widget build(BuildContext context) {
    Uint8List? decodedImage;
    String? errorMessage;

    try {
      decodedImage = base64Image.contains(',')
          ? base64Decode(base64Image.split(',').last)
          : base64Decode(base64Image);
    } catch (e) {
      errorMessage = 'Failed to load QR code: ${e.toString()}';
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (errorMessage != null) ...[
          Text(
            errorMessage,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: ElevatedButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ),
        ] else if (decodedImage != null) ...[
          const Text(
            'Scan this QR at the gate',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          Image.memory(
            decodedImage,
            width: MediaQuery.of(context).size.width * 0.6,
            height: MediaQuery.of(context).size.width * 0.6,
          ),
        ],
      ],
    );
  }
}
