
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:safenest/api_services/file.dart';
import 'package:safenest/features/dashboard/update_sections/update_teacher.dart';
import 'package:safenest/features/qr_code_management/qr_scanner_screen.dart';
import 'package:safenest/features/user_management/change_password_screen.dart';

class TeacherDashboard extends StatefulWidget {
  final String userId; // Changed to non-nullable String
  const TeacherDashboard({super.key, required this.userId});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  late Future<Map<String, dynamic>> _teacherProfile;
  late Future<List<dynamic>> _pickupLogs;
  String _teacherName = 'Teacher';
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _teacherProfile = _fetchTeacherProfile();
      _pickupLogs = _fetchPickupLogs();
    });
  }

  Future<Map<String, dynamic>> _fetchTeacherProfile() async {
    try {
      final profile = await ApiService.safeApiCall(() => ApiService.getTeacherProfile(userId: widget.userId));
      if (mounted) {
        setState(() {
          _teacherName = profile['fullName'] ?? 'Teacher';
        });
      }
      return profile;
    } on ApiException catch (e) {
      throw ApiException('Failed to load teacher profile: ${e.message}', statusCode: e.statusCode);
    } catch (e) {
      throw ApiException('Failed to load teacher profile: ${e.toString()}');
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

  Future<void> _logout() async {
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
          const SnackBar(content: Text('Logout failed: An unexpected error occurred')),
        );
      }
    }
  }

  Future<void> _verifyQRCode() async {
    if (!mounted || _isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final qrCode = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (context) => const QRScannerScreen()),
      );

      if (qrCode == null || !mounted) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final response = await ApiService.safeApiCall(
        () => ApiService.verifyQRCode(qrCode),
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'QR code verified')),
        );
        _handleRefresh();
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = _mapErrorToMessage(e);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to verify QR code: ${_mapErrorToMessage(e)}')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'An unexpected error occurred';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An unexpected error occurred')),
        );
      }
    }
  }

  String _mapErrorToMessage(ApiException e) {
    switch (e.message) {
      case 'Invalid QR code':
        return 'The scanned QR code is invalid';
      case 'Network error':
        return 'Please check your internet connection';
      case 'Unauthorized':
        return 'Please log in again';
      default:
        return e.message;
    }
  }

  void updateTeacher() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UpdateTeacherScreen(userId: widget.userId),
      ),
    ).then((result) {
      if (result == true && mounted) {
        _handleRefresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat.yMMMMd().add_jm().format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFF5271FF),
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
        centerTitle: true,
        backgroundColor: const Color(0xFF5271FF),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'refresh') {
                _handleRefresh();
              } else if (value == 'update_profile') {
                updateTeacher();
              } else if (value == 'change_password') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                ).then((result) {
                  if (result == true && mounted) {
                    _handleRefresh();
                  }
                });
              }
            },
            itemBuilder: (BuildContext context) => const [
              PopupMenuItem(value: 'refresh', child: Text('Refresh Data')),
              PopupMenuItem(value: 'update_profile', child: Text('Update Profile')),
              PopupMenuItem(value: 'change_password', child: Text('Change Password')),
            ],
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.white),
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
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: constraints.maxHeight),
                          child: IntrinsicHeight(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const SizedBox(height: 20),
                                Text(
                                  '👋 Hello, $_teacherName!',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '📅 $formattedDate',
                                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
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
                                FutureBuilder<Map<String, dynamic>>(
                                  future: _teacherProfile,
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting || _isLoading) {
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
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                                const SizedBox(height: 16),
                                Card(
                                  elevation: 6,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  color: const Color(0xFF5271FF),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: _isLoading ? null : _verifyQRCode,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.qr_code_scanner, color: Colors.white, size: 32),
                                          const SizedBox(width: 16),
                                          const Text(
                                            'Scan QR Code',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              letterSpacing: 1.2,
                                            ),
                                          ),
                                          if (_isLoading) ...[
                                            const

 SizedBox(width: 16),
                                            const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2.5,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  'Recent Pickups',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                FutureBuilder<List<dynamic>>(
                                  future: _pickupLogs,
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting || _isLoading) {
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
                                      return const Center(child: Text('No pickup logs found', style: TextStyle(color: Colors.grey)));
                                    }

                                    return ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: snapshot.data!.length,
                                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                                      itemBuilder: (context, index) {
                                        final log = snapshot.data![index];
                                        final childName = log['fullName'] ?? 'Unknown Child';
                                        final parentName = log['parentName'] ?? 'Unknown Parent';
                                        final dateTime = DateTime.tryParse(log['verifiedAt'] ?? '');
                                        final formattedTime = dateTime != null
                                            ? DateFormat('MMM d, h:mm a').format(dateTime)
                                            : 'Unknown time';
                                        return Card(
                                          elevation: 3,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          child: ListTile(
                                            contentPadding: const EdgeInsets.all(12),
                                            leading: const Icon(Icons.check_circle, color: Colors.green, size: 24),
                                            title: Text('$childName picked up by $parentName',
                                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                                            subtitle: Text(formattedTime, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                                            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
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
