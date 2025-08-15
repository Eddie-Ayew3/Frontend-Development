import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:safenest/Api_Service/pickup_log.dart';

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
  static const String _baseUrl = 'https://5497133f5759.ngrok-free.app/v1';
  static const Duration _timeoutDuration = Duration(seconds: 60);
  static const _storage = FlutterSecureStorage();

  static const _tokenKey = 'auth_token';
  static const _emailKey = 'user_email';
  static const _fullnameKey = 'user_fullname';
  static const _roleKey = 'user_role';
  static const _roleIdKey = 'user_roleId';
  static const _expirationKey = 'token_expiration';

  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: _timeoutDuration,
      receiveTimeout: _timeoutDuration,
      headers: {
        'accept': '*/*',
        'Content-Type': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await getAuthToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        debugPrint('Request: ${options.method} ${options.uri}');
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          debugPrint('401 detected, attempting token refresh');
          final refreshed = await _refreshToken();
          if (refreshed) {
            return handler.resolve(await _retryRequest(error.requestOptions));
          } else {
            await clearUserData();
            throw ApiException('Session expired. Please login again.', 401);
          }
        }
        return handler.next(error);
      },
    ));
  }

  // ------------------------
  // Storage Helpers
  // ------------------------
static Future<void> setUserData({
  required String token,
  required String email,
  required String fullname,
  required String role,
  required String roleId,
  required String expiration,
}) async {
  try {
    debugPrint('Attempting to save user data...');
    
    // Write all data in a transaction
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _emailKey, value: email);
    await _storage.write(key: _fullnameKey, value: fullname);
    await _storage.write(key: _roleKey, value: role);
    await _storage.write(key: _roleIdKey, value: roleId);
    await _storage.write(key: _expirationKey, value: expiration);
    
    // Immediate verification
    final savedToken = await _storage.read(key: _tokenKey);
    if (savedToken != token) {
      throw Exception('Token verification failed after save');
    }
    
    debugPrint('User data saved and verified successfully');
  } catch (e) {
    debugPrint('Error saving user data: $e');
    await _storage.deleteAll(); // Clear potentially corrupted data
    rethrow;
  }
}


  static Future<Map<String, String?>> getUserData() async {
    final token = await _storage.read(key: _tokenKey);
    final email = await _storage.read(key: _emailKey);
    final fullname = await _storage.read(key: _fullnameKey);
    final role = await _storage.read(key: _roleKey);
    final roleId = await _storage.read(key: _roleIdKey);
    final expiration = await _storage.read(key: _expirationKey);
    debugPrint('Read from storage: token=${token != null ? "FOUND" : "NULL"}, expiration=$expiration');
    return {
      'token': token,
      'email': email,
      'fullname': fullname,
      'role': role,
      'roleId': roleId,
      'expiration': expiration,
    };
  }

static Future<String?> getAuthToken() async {
  try {
    // First attempt
    var token = await _storage.read(key: _tokenKey);
    
    if (token == null) {
      debugPrint('Primary token storage failed, checking backup...');
      // Check if we have a cached version in memory
      token = _cachedToken;
      
      token ??= await _getTempToken();
    }
    
    debugPrint('Retrieved token: ${token != null ? "[HIDDEN]" : "NULL"}');
    return token;
  } catch (e) {
    debugPrint('Error retrieving token: $e');
    return null;
  }
}

// Add these class variables at the top of ApiService
static String? _cachedToken;
static const _tempTokenKey = 'temp_auth_token';

static Future<String?> _getTempToken() async {
  try {
    return await _storage.read(key: _tempTokenKey);
  } catch (e) {
    return null;
  }
}
  static Future<void> clearUserData() async {
    debugPrint('Clearing user data from storage.');
    await _storage.deleteAll();
  }

  // ------------------------
  // Token & Auth Checks
  // ------------------------

  Future<bool> _refreshToken() async {
    try {
      final token = await getAuthToken();
      if (token == null) return false;

      final response = await _dio.post('/auth/refresh-token');
      final data = response.data;
      debugPrint('Refresh token response: ${response.statusCode} - $data');

      if (response.statusCode == 200) {
        final newToken = data['token'];
        final newExpiration = data['expiration'] ??
            DateTime.now().toUtc().add(const Duration(days: 1)).toIso8601String();

        if (newToken != null) {
          await _storage.write(key: _tokenKey, value: newToken);
          await _storage.write(key: _expirationKey, value: newExpiration);
          debugPrint('Token refreshed and saved.');
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Token refresh failed: $e');
      return false;
    }
  }

  Future<Response> _retryRequest(RequestOptions options) async {
    final token = await getAuthToken();
    options.headers['Authorization'] = 'Bearer $token';
    return await _dio.request(
      options.path,
      data: options.data,
      queryParameters: options.queryParameters,
      options: Options(
        method: options.method,
        headers: options.headers,
      ),
    );
  }

  // ------------------------
  // Authentication APIs
  // ------------------------
  Future<Map<String, dynamic>> login({
  required String email,
  required String password,
}) async {
  try {
    final response = await _dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );

    final data = response.data;
    debugPrint('Login response: ${response.statusCode} - ${data.containsKey('token')}');

    if (response.statusCode == 200) {
      final token = data['token'] as String?;
      if (token == null || token.isEmpty) {
        throw ApiException('Login succeeded but no token received', 200);
      }

      // Cache token in memory as backup
      _cachedToken = token;
      
      // Store in temporary location as additional backup
      await _storage.write(key: _tempTokenKey, value: token);

      await setUserData(
        token: token,
        email: email,
        fullname: data['fullname'] ?? '',
        role: data['role'] ?? '',
        roleId: data['roleId']?.toString() ?? '',
        expiration: data['expiration']?.toString() ?? 
            DateTime.now().toUtc().add(const Duration(days: 1)).toIso8601String(),
      );

      // Final verification
      final verifiedToken = await getAuthToken();
      if (verifiedToken == null) {
        throw ApiException('Token storage verification failed', 500);
      }

      return data;
    }
    throw ApiException('Login failed', response.statusCode);
  } on DioException catch (e) {
    throw ApiException(
      e.response?.data['message']?.toString() ?? 'Login error',
      e.response?.statusCode,
    );
  }
}
  
Future<Map<String, dynamic>> register({
  required String fullname,
  required String email,
  required String password,
  required String role,
}) async {
  try {
    final response = await _dio.post(
      '/auth/register',
      data: {
        'fullname': fullname,
        'email': email,
        'password': password,
        'role': role,
      },
    );
    
    final data = response.data;
    debugPrint('Register response: ${response.statusCode} - $data');

    if (response.statusCode == 201) {
      // Add null checks and validation
      final token = data['token'] as String?;
      if (token == null || token.isEmpty) {
        throw ApiException('Registration succeeded but no token received', 201);
      }

      await setUserData(
        token: token,
        email: email,
        fullname: fullname,
        role: role,
        roleId: data['roleId']?.toString() ?? '', // Ensure string conversion
        expiration: data['expiration']?.toString() ?? 
            DateTime.now().toUtc().add(const Duration(days: 1)).toIso8601String(),
      );

      // Verify storage
      final storedToken = await getAuthToken();
      if (storedToken == null) {
        throw ApiException('Failed to persist authentication token', 500);
      }

      return data;
    }
    throw ApiException('Registration failed', response.statusCode);
  } on DioException catch (e) {
    throw ApiException(
      e.response?.data['message']?.toString() ?? 'Registration error',
      e.response?.statusCode,
    );
  }
}

  // ------------------------
  // Child-related APIs
  // ------------------------
// Update getParentChildren method
Future<List<Map<String, dynamic>>> getParentChildren() async {
  try {
    final response = await _dio.get('/parents/children');
    final data = response.data;
    if (data is List) {
      return data.map((child) {
        // Split fullname into first and last names
        final names = (child['fullname'] as String?)?.split(' ') ?? ['Unknown', ''];
        final firstName = names.first;
        final lastName = names.length > 1 ? names.sublist(1).join(' ') : '';
        
        return {
          'id': child['childID']?.toString() ?? '',
          'firstName': firstName,
          'lastName': lastName,
          'grade': child['grade'] ?? '',
          'fullname': child['fullname'] ?? '',
        };
      }).toList();
    }
    throw ApiException('Invalid response format');
  } on DioException catch (e) {
    throw ApiException(
      e.response?.data['message'] ?? 'Get children error',
      e.response?.statusCode,
    );
  }
}
Future<List<Map<String, dynamic>>> getTeacherClassStudents(String userId) async {
  try {
    final response = await _dio.get('/teacher/class-students/$userId');
    final data = response.data;
    if (data is List) {
      return data.map((student) {
        return {
          'childID': student['childID']?.toString() ?? '',
          'fullname': student['fullname'] ?? 'Unknown',
          'grade': student['grade'] ?? 'N/A',
          'gender': student['gender'] ?? 'Unknown',
        };
      }).toList();
    }
    throw ApiException('Invalid response format');
  } on DioException catch (e) {
    throw ApiException(
      e.response?.data['message'] ?? 'Failed to fetch class students',
      e.response?.statusCode,
    );
  }
}

// Update getPickupLogs method
Future<List<PickupLog>> getPickupLogs() async {
  try {
    final response = await _dio.get('/qr/logs');
    final data = response.data;
    if (data is List) {
      return data.map((log) => PickupLog.fromJson(log)).toList();
    }
    throw ApiException('Invalid response format');
  } on DioException catch (e) {
    throw ApiException(
      e.response?.data['message'] ?? 'Failed to fetch pickup logs',
      e.response?.statusCode,
    );
  }
}
Future<Map<String, dynamic>> addChild({
  required String fullname,
  required String grade,
  required String gender,
  required String parentID,
}) async {
  try {
    final response = await _dio.post(
      '/children', // Remove '/v1' (already in _baseUrl)
      data: {
        'parentID': parentID, // Match old API's field name
        'fullname': fullname,
        'grade': grade,
        'gender': gender,
      },
    );

    final data = response.data;
    debugPrint('Create child response: ${response.statusCode} - $data');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {
        'message': data['message'] ?? 'Child created successfully',
        'id': data['id']?.toString() ?? '', // Ensure String type
      };
    }
    throw ApiException(
      data['message'] ?? 'Failed to create child',
      response.statusCode,
    );
  } on DioException catch (e) {
    throw ApiException(
      e.response?.data['message'] ?? 'Failed to create child',
      e.response?.statusCode,
    );
  }
}

Future<String> generateChildQRCode({
  required String childId,
  required String token,
}) async {
  try {
    final url = '/qr/generate?childId=$childId';
    debugPrint('Generate QR code request: $url, childId=$childId');
    
    final response = await _dio.post(
      url,
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ),
    );

    final data = response.data;
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
  } on DioException catch (e) {
    debugPrint('Generate QR code error: ${e.response?.statusCode} - ${e.response?.data}');
    throw ApiException(
      e.response?.data['message'] ?? 'QR code generation error',
      e.response?.statusCode,
    );
  }
}


Future<Map<String, dynamic>> verifyQRCode({
  required String qrCode,
}) async {
  try {
    final response = await _dio.post(
      '/qr/verify',
      data: {'qrCode': qrCode.trim()},
    );

    debugPrint('Verify QR code response: ${response.data}');
    return response.data;
  } on DioException catch (e) {
    debugPrint('''
    Verify QR Error:
    URL: ${e.requestOptions.uri}
    Status: ${e.response?.statusCode}
    Response: ${e.response?.data}
    ''');

    final errorMsg = e.response?.data['message'] ?? 'Verification failed';
    switch (e.response?.statusCode) {
      case 400:
        throw ApiException('Invalid QR: $errorMsg', e.response?.statusCode);
      case 401:
        throw ApiException('Session expired. Please login again', e.response?.statusCode);
      case 403:
        throw ApiException('Permission denied: $errorMsg', e.response?.statusCode);
      case 404:
        throw ApiException('Record not found: $errorMsg', e.response?.statusCode);
      case 409:
        throw ApiException('Already verified: $errorMsg', e.response?.statusCode);
      default:
        throw ApiException('Error ${e.response?.statusCode}: $errorMsg', e.response?.statusCode);
    }
  }
}

  // ------------------------
  // User Management APIs
  // ------------------------
  Future<Map<String, dynamic>> addParent({
    required String email,
    required String fullname,
    required String phone,
    required String location,
  }) async {
    try {
      final response = await _dio.post(
        '/parents',
        data: {
          'email': email,
          'fullname': fullname,
          'phone': phone,
          'location': location,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw ApiException(
        e.response?.data['message'] ?? 'Add parent error',
        e.response?.statusCode,
      );
    }
  }

  Future<Map<String, dynamic>> addTeacher({
    required String email,
    required String fullname,
    required String phone,
    required String grade,
  }) async {
    try {
      final response = await _dio.post(
        '/teachers',
        data: {
          'email': email,
          'fullname': fullname,
          'phone': phone,
          'grade': grade,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw ApiException(
        e.response?.data['message'] ?? 'Add teacher error',
        e.response?.statusCode,
      );
    }
  }

Future<Map<String, dynamic>> updateParent({
  required int parentId,
  required String token,
  required String phone,
  required String location,
}) async {
  try {
    final response = await _dio.put(
      '/parents/$parentId',
      data: {
        'phone': phone,
        'location': location,
      },
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );

    debugPrint('Update parent response: ${response.statusCode} - ${response.data}');
    return response.data;
  } on DioException catch (e) {
    debugPrint('Update parent error: ${e.response?.statusCode} - ${e.response?.data}');
    throw ApiException(
      e.response?.data['message'] ?? 'Failed to update parent',
      e.response?.statusCode,
    );
  }
}

Future<Map<String, dynamic>> updateTeacher({
  required int teacherId,  // Changed to int to match backend
  required String? phone,  // Made nullable
  required String? grade,  // Made nullable
  required String token,
}) async {
  try {
    // Debug print to verify request data
    debugPrint('''
    Updating teacher:
    ID: $teacherId
    Phone: $phone
    Grade: $grade
    ''');

    final response = await _dio.put(
      '/teacher/$teacherId',  // Matches your [HttpPut("{teacherId}")]
      data: {
        'phone': phone,
        'grade': grade,
      },
      options: Options(
        headers: {
          'accept': '*/*',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );

    debugPrint('Update successful: ${response.data}');
    return response.data;
  } on DioException catch (e) {
    debugPrint('''
    Update failed:
    URL: ${e.requestOptions.uri}
    Status: ${e.response?.statusCode}
    Response: ${e.response?.data}
    ''');

    // Handle specific error cases from your backend
    if (e.response?.statusCode == 400) {
      final errorData = e.response?.data;
      if (errorData is Map && errorData['message'] != null) {
        throw ApiException(errorData['message'], 400);
      }
    }

    throw ApiException(
      e.response?.data['message'] ?? 'Failed to update teacher profile',
      e.response?.statusCode ?? 500,
    );
  }
}

  // ------------------------
  // Dashboard and Logs APIs
  // ------------------------
  Future<Map<String, dynamic>> getAdminDashboard() async {
    try {
      final response = await _dio.get('/admin/Data');
      return response.data;
    } on DioException catch (e) {
      throw ApiException(
        e.response?.data['message'] ?? 'Get dashboard error',
        e.response?.statusCode,
      );
    }
  }





  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
      await clearUserData();
    } catch (e) {
      debugPrint('Logout error: $e');
      await clearUserData();
    }
  }
}