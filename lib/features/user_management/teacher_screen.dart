import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:safenest/features/dashboard/update_sections/update_teacher.dart';
import 'package:safenest/features/qr_code_management/qr_scanner_screen.dart';
import 'package:safenest/api_services/file.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

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
      return await ApiService.safeApiCall(() => ApiService.getTeacherProfile());
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

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

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
          _isLoading = false;
          _errorMessage = _mapErrorToMessage(e);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: ${_mapErrorToMessage(e)}')),
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

  Future<void> _verifyQRCode() async {
    if (!mounted || _isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Navigate to QRScannerScreen or open scanner
      final qrCode = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (context) => const QRScannerScreen(),
        ),
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
        _handleRefresh(); // Refresh pickup logs
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
  Future<void> updateTeacher() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UpdateTeacherScreen()),
    );
    if (result == true && mounted) {
      _handleRefresh(); // Refresh data after update
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat.yMMMMd().add_jm().format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFF5271FF),
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
        backgroundColor: const Color(0xFF5271FF),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'refresh') {
                _handleRefresh();
              }else if (value == 'update_profile') {
                updateTeacher();
              }

            },
            itemBuilder: (BuildContext context) => const [
              PopupMenuItem(value: 'refresh', child: Text('Refresh Data')),
              PopupMenuItem(value: 'update_profile', child: Text('Update Profile')),
            ],
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 40),
                Center(
                  child: Image.asset('assets/safenest_icon.png', height: 120),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '📅 $formattedDate',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      FutureBuilder<Map<String, dynamic>>(
                        future: _teacherProfile,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            String errorMessage = snapshot.error is ApiException
                                ? _mapErrorToMessage(snapshot.error as ApiException)
                                : 'Error: ${snapshot.error.toString()}';
                            setState(() {
                              _errorMessage = errorMessage;
                            });
                            return Text('Error: $errorMessage');
                          } else if (snapshot.hasData) {
                            _teacherName = snapshot.data!['fullName'] ?? 'Teacher';
                            return Text(
                              'Hello, $_teacherName!',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          }
                          return const Text(
                            'Hello, Teacher!',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _verifyQRCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5271FF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Scan QR Code',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Recent Pickups',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FutureBuilder<List<dynamic>>(
                        future: _pickupLogs,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            String errorMessage = snapshot.error is ApiException
                                ? _mapErrorToMessage(snapshot.error as ApiException)
                                : 'Error: ${snapshot.error.toString()}';
                            setState(() {
                              _errorMessage = errorMessage;
                            });
                            return Center(
                              child: Column(
                                children: [
                                  Text('Error: $errorMessage'),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _handleRefresh,
                                    child: const Text('Retry'),
                                  ),
                                ],
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
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}