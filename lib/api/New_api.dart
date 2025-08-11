import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:safenest/api/pickup_log.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => statusCode != null
      ? 'ApiException: $message (Status $statusCode)'
      : 'ApiException: $message';
}

class ApiService {
  static const String _baseUrl = 'https://c2e7685a5bb3.ngrok-free.app/v1';
  static const Duration _timeoutDuration = Duration(seconds: 60);
  static const Duration _tokenExpirationThreshold = Duration(minutes: 5);
  static const _storage = FlutterSecureStorage();

  static const _tokenKey = 'auth_token';
  static const _emailKey = 'user_email';
  static const _fullnameKey = 'user_fullname';
  static const _roleKey = 'user_role';
  static const _roleIdKey = 'user_roleId';
  static const _expirationKey = 'token_expiration';

  static Future<dynamic> safeApiCall(Future<dynamic> Function() apiCall) async {
    try {
      final authData = await checkAuthStatus();
      if (authData == null) {
        throw ApiException('Session expired. Please login again.', 401);
      }
      return await apiCall().timeout(_timeoutDuration);
    } on http.ClientException catch (e) {
      throw ApiException('Network error: ${e.message}');
    } on TimeoutException {
      throw ApiException('Request timed out');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('An unexpected error occurred: $e');
    }
  }

  static Future<void> setUserData({
    required String token,
    required String email,
    required String fullname,
    required String role,
    required String roleId,
    required String expiration,
  }) async {
    debugPrint('Saving user data: email=$email, fullname=$fullname, role=$role, roleId=$roleId');
    await Future.wait([
      _storage.write(key: _tokenKey, value: token),
      _storage.write(key: _emailKey, value: email),
      _storage.write(key: _fullnameKey, value: fullname),
      _storage.write(key: _roleKey, value: role),
      _storage.write(key: _roleIdKey, value: roleId),
      _storage.write(key: _expirationKey, value: expiration),
    ]);
  }

  static Future<Map<String, String?>> getUserData() async {
    final data = await Future.wait([
      _storage.read(key: _tokenKey),
      _storage.read(key: _emailKey),
      _storage.read(key: _fullnameKey),
      _storage.read(key: _roleKey),
      _storage.read(key: _roleIdKey),
      _storage.read(key: _expirationKey),
    ]);
    return {
      'token': data[0],
      'email': data[1],
      'fullname': data[2],
      'role': data[3],
      'roleId': data[4],
      'expiration': data[5],
    };
  }

  static Future<String?> getAuthToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<void> clearUserData() async {
    debugPrint('Clearing user data');
    await _storage.deleteAll();
  }

  static bool _isTokenExpired(String? expiration) {
    if (expiration == null) return true;
    try {
      final expirationDate = DateTime.parse(expiration).toUtc();
      final now = DateTime.now().toUtc();
      return expirationDate.isBefore(now.add(_tokenExpirationThreshold));
    } catch (e) {
      debugPrint('Error parsing token expiration: $e');
      return true;
    }
  }

  static Future<Map<String, dynamic>?> checkAuthStatus() async {
    final userData = await getUserData();
    final token = userData['token'];
    final expiration = userData['expiration'];

    if (token == null) {
      debugPrint('No token found in storage');
      return null;
    }

    if (_isTokenExpired(expiration)) {
      debugPrint('Token expired, attempting refresh');
      try {
        final newToken = await refreshToken();
        final updatedData = await getUserData();
        return {
          'token': newToken,
          'email': updatedData['email'],
          'fullname': updatedData['fullname'],
          'role': updatedData['role'],
          'roleId': updatedData['roleId'],
          'expiration': updatedData['expiration'],
        };
      } catch (e) {
        debugPrint('Token refresh failed: $e');
        await clearUserData();
        return null;
      }
    }

    return {
      'token': token,
      'email': userData['email'],
      'fullname': userData['fullname'],
      'role': userData['role'],
      'roleId': userData['roleId'],
      'expiration': expiration,
    };
  }

  static Future<String> refreshToken() async {
    final token = await getAuthToken();
    if (token == null) throw ApiException('No token available');

    final url = Uri.parse('$_baseUrl/auth/refresh-token');
    debugPrint('Refreshing token: $url');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(_timeoutDuration);

    final data = jsonDecode(response.body);
    debugPrint('Refresh token response: ${response.statusCode} - $data');

    if (response.statusCode == 200) {
      final newToken = data['token'];
      final newExpiration = data['expiration'] ??
          DateTime.now().toUtc().add(const Duration(days: 1)).toIso8601String();

      if (newToken != null) {
        await Future.wait([
          _storage.write(key: _tokenKey, value: newToken),
          _storage.write(key: _expirationKey, value: newExpiration),
        ]);
        return newToken;
      }
      throw ApiException('Invalid token response');
    }
    throw ApiException(
      data['message'] ?? 'Token refresh failed',
      response.statusCode,
    );
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    return await safeApiCall(() async {
      final url = Uri.parse('$_baseUrl/auth/login');
      debugPrint('Login request: $url, email=$email');
      final response = await http.post(
        url,
        headers: {
          'accept': '*/*',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(_timeoutDuration);

      final data = jsonDecode(response.body);
      debugPrint('Login response: ${response.statusCode} - $data');

      if (response.statusCode == 200) {
        await setUserData(
          token: data['token'],
          email: data['email'],
          fullname: data['fullname'],
          role: data['role'],
          roleId: data['roleId'].toString(),
          expiration: data['expiration'],
        );
        return data;
      }
      throw ApiException(
        data['message'] ?? 'Login failed',
        response.statusCode,
      );
    });
  }

  static Future<Map<String, dynamic>> register({
    required String fullname,
    required String email,
    required String password,
    required String role,
  }) async {
    return await safeApiCall(() async {
      final url = Uri.parse('$_baseUrl/auth/register');
      debugPrint('Register request: $url, email=$email, role=$role');
      final response = await http.post(
        url,
        headers: {
          'accept': '*/*',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'fullname': fullname,
          'email': email,
          'password': password,
          'role': role,
        }),
      ).timeout(_timeoutDuration);

      final data = jsonDecode(response.body);
      debugPrint('Register response: ${response.statusCode} - $data');

      if (response.statusCode == 200 || response.statusCode == 201) {
        await setUserData(
          token: data['token'] ?? '',
          email: data['email'] ?? email,
          fullname: data['fullname'] ?? fullname,
          role: data['role'] ?? role,
          roleId: data['id'].toString(),
          expiration: data['expiration'] ??
              DateTime.now().toUtc().add(const Duration(days: 1)).toIso8601String(),
        );
        return {
          'message': data['message'],
          'id': data['id'].toString(),
          'role': role,
          'token': data['token'] ?? '',
          'email': data['email'] ?? email,
          'fullname': data['fullname'] ?? fullname,
          'expiration': data['expiration'] ??
              DateTime.now().toUtc().add(const Duration(days: 1)).toIso8601String(),
        };
      }
      throw ApiException(
        data['message'] ?? 'Registration failed',
        response.statusCode,
      );
    });
  }

  static Future<Map<String, dynamic>> createParent({
    required String token,
    required String fullname,
    required String email,
    required String phone,
    required String location,
  }) async {
    return await safeApiCall(() async {
      final url = Uri.parse('$_baseUrl/parents');
      debugPrint('Create parent request: $url, email=$email');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'fullname': fullname,
          'email': email,
          'phone': phone,
          'location': location,
        }),
      );

      final data = jsonDecode(response.body);
      debugPrint('Create parent response: ${response.statusCode} - $data');

      if (response.statusCode == 201) {
        return {
          'message': data['message'] ?? 'Parent created successfully',
          'id': data['id'],
        };
      }
      throw ApiException(
        data['message'] ?? 'Failed to create parent',
        response.statusCode,
      );
    });
  }

  static Future<Map<String, dynamic>> createTeacher({
    required String token,
    required String fullname,
    required String phone,
    required String email,
    required String grade,
  }) async {
    return await safeApiCall(() async {
      final url = Uri.parse('$_baseUrl/teachers');
      debugPrint('Create teacher request: $url, email=$email, grade=$grade');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'fullname': fullname,
          'phone': phone,
          'email': email,
          'grade': grade,
        }),
      );

      final data = jsonDecode(response.body);
      debugPrint('Create teacher response: ${response.statusCode} - $data');

      if (response.statusCode == 201) {
        return {
          'message': data['message'] ?? 'Teacher created successfully',
          'id': data['id'],
        };
      }
      throw ApiException(
        data['message'] ?? 'Failed to create teacher',
        response.statusCode,
      );
    });
  }

  static Future<Map<String, dynamic>> createChild({
    required String token,
    required String parentId,
    required String fullname,
    required String grade,
    required String gender,
  }) async {
    return await safeApiCall(() async {
      final url = Uri.parse('$_baseUrl/children');
      debugPrint('Create child request: $url, parentId=$parentId, fullname=$fullname');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'parentID': parentId,
          'fullname': fullname,
          'grade': grade,
          'gender': gender,
        }),
      );

      final data = jsonDecode(response.body);
      debugPrint('Create child response: ${response.statusCode} - $data');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'message': data['message'] ?? 'Child created successfully',
          'id': data['id'],
        };
      }
      throw ApiException(
        data['message'] ?? 'Failed to create child',
        response.statusCode,
      );
    });
  }

  static Future<List<Map<String, dynamic>>> getParentChildren({
    required String token,
  }) async {
    return await safeApiCall(() async {
      final url = Uri.parse('$_baseUrl/parents/children');
      debugPrint('Get parent children request: $url');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('Get parent children response: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is! List) {
          throw ApiException('Invalid response format: Expected a list of children');
        }
        return data.map((child) {
          if (child is! Map) {
            throw ApiException('Invalid child data format');
          }
          return {
            'childID': child['childID']?.toString() ?? '',
            'fullname': child['fullname']?.toString() ?? 'Unknown',
            'grade': child['grade']?.toString() ?? 'N/A',
          };
        }).toList();
      }

      final errorData = jsonDecode(response.body);
      throw ApiException(
        errorData['message'] ?? 'Failed to fetch children',
        response.statusCode,
      );
    });
  }

  static Future<String> generateChildQRCode({
    required String childId,
    required String token,
  }) async {
    return await safeApiCall(() async {
      final url = Uri.parse('$_baseUrl/qr/generate?childId=$childId');
      debugPrint('Generate QR code request: $url, childId=$childId');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      debugPrint('Generate QR code response: ${response.statusCode} - $data');

      if (response.statusCode == 200) {
        if (data['qrCode'] == null) {
          throw ApiException('QR code not found in response');
        }
        return data['qrCode'].toString();
      }

      throw ApiException(
        data['message'] ?? 'Failed to generate QR code',
        response.statusCode,
      );
    });
  }

  static Future<Map<String, dynamic>> verifyQRCode({
    required String qrCode,
    required String token,
  }) async {
    return await safeApiCall(() async {
      final url = Uri.parse('$_baseUrl/qr/verify');
      debugPrint('Verify QR code request: $url');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'qrCode': qrCode.trim(),
        }),
      );

      final data = jsonDecode(response.body);
      debugPrint('Verify QR code response: ${response.statusCode} - $data');

      if (response.statusCode == 200) {
        return data;
      }

      final errorMsg = data['message'] ?? 'Verification failed';
      switch (response.statusCode) {
        case 400:
          throw ApiException('Invalid QR: $errorMsg', response.statusCode);
        case 401:
          throw ApiException('Session expired. Please login again', response.statusCode);
        case 403:
          throw ApiException('Permission denied: $errorMsg', response.statusCode);
        case 404:
          throw ApiException('Record not found: $errorMsg', response.statusCode);
        case 409:
          throw ApiException('Already verified: $errorMsg', response.statusCode);
        default:
          throw ApiException('Error ${response.statusCode}: $errorMsg', response.statusCode);
      }
    });
  }

  static Future<Map<String, dynamic>> updateParent({
    required String token,
    required String userId,
    required String phone,
    required String location,
  }) async {
    return await safeApiCall(() async {
      final url = Uri.parse('$_baseUrl/parents/$userId');
      debugPrint('Update parent request: $url, phone=$phone, location=$location');
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'phone': phone,
          'location': location,
        }),
      );

      final data = jsonDecode(response.body);
      debugPrint('Update parent response: ${response.statusCode} - $data');

      if (response.statusCode == 200) {
        return data;
      }

      throw ApiException(
        data['message'] ?? 'Failed to update parent',
        response.statusCode,
      );
    });
  }

  static Future<Map<String, dynamic>> updateTeacher({
    required String token,
    required String userId,
    required String phone,
    required String grade,
  }) async {
    return await safeApiCall(() async {
      final url = Uri.parse('$_baseUrl/teachers/$userId');
      debugPrint('Update teacher request: $url, phone=$phone, grade=$grade');
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'phone': phone,
          'grade': grade,
        }),
      );

      final data = jsonDecode(response.body);
      debugPrint('Update teacher response: ${response.statusCode} - $data');

      if (response.statusCode == 200) {
        return data;
      }

      throw ApiException(
        data['message'] ?? 'Failed to update teacher',
        response.statusCode,
      );
    });
  }

  static Future<Map<String, dynamic>> getAdminDashboard(String token) async {
    return await safeApiCall(() async {
      final url = Uri.parse('$_baseUrl/admin/Data');
      debugPrint('Get admin dashboard request: $url');
      final response = await http.get(
        url,
        headers: {
          'accept': '*/*',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      debugPrint('Get admin dashboard response: ${response.statusCode} - $data');

      if (response.statusCode == 200) {
        return data;
      }

      throw ApiException(
        data['message'] ?? 'Failed to fetch dashboard data',
        response.statusCode,
      );
    });
  }

  static Future<List<PickupLog>> getPickupLogs(String token) async {
    return await safeApiCall(() async {
      final url = Uri.parse('$_baseUrl/admin/pickup-logs');
      debugPrint('Get admin pickup logs request: $url');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('Get admin pickup logs response: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is! List) {
          throw ApiException('Invalid response format: Expected a list of logs');
        }
        return data.map((log) => PickupLog.fromJson(log)).toList();
      }

      final errorData = jsonDecode(response.body);
      throw ApiException(
        errorData['message'] ?? 'Failed to fetch admin pickup logs',
        response.statusCode,
      );
    });
  }

  static Future<List<PickupLog>> getParentPickupLogs(String token) async {
    return await safeApiCall(() async {
      final userData = await getUserData();
      final parentId = userData['roleId'];
      if (parentId == null) {
        throw ApiException('Parent ID not found in user data');
      }
      final url = Uri.parse('$_baseUrl/parents/$parentId/pickup-logs');
      debugPrint('Get parent pickup logs request: $url, parentId=$parentId');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('Get parent pickup logs response: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is! List) {
          throw ApiException('Invalid response format: Expected a list of logs');
        }
        return data.map((log) => PickupLog.fromJson(log)).toList();
      }

      final errorData = jsonDecode(response.body);
      throw ApiException(
        errorData['message'] ?? 'Failed to fetch parent pickup logs',
        response.statusCode,
      );
    });
  }

  static Future<List<PickupLog>> getTeacherPickupLogs(String token) async {
    return await safeApiCall(() async {
      final userData = await getUserData();
      final teacherId = userData['roleId'];
      if (teacherId == null) {
        throw ApiException('Teacher ID not found in user data');
      }
      final url = Uri.parse('$_baseUrl/teachers/$teacherId/pickup-logs');
      debugPrint('Get teacher pickup logs request: $url, teacherId=$teacherId');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('Get teacher pickup logs response: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is! List) {
          throw ApiException('Invalid response format: Expected a list of logs');
        }
        return data.map((log) => PickupLog.fromJson(log)).toList();
      }

      final errorData = jsonDecode(response.body);
      throw ApiException(
        errorData['message'] ?? 'Failed to fetch teacher pickup logs',
        response.statusCode,
      );
    });
  }

  static Future<void> logout() async {
    await safeApiCall(() async {
      final token = await getAuthToken();
      await clearUserData();
      if (token == null) return;

      final url = Uri.parse('$_baseUrl/auth/logout');
      debugPrint('Logout request: $url');
      final response = await http.post(
        url,
        headers: {
          'accept': '*/*',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));

      debugPrint('Logout response: ${response.statusCode}');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return;
      }

      try {
        final data = jsonDecode(response.body);
        throw ApiException(
          data['message'] ?? 'Logout failed',
          response.statusCode,
        );
      } catch (_) {
        throw ApiException(
          'Logout failed with status ${response.statusCode}',
          response.statusCode,
        );
      }
    });
  }
}