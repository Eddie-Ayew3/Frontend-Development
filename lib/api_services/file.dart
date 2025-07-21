import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException: $message${statusCode != null ? ' (Status Code: $statusCode)' : ''}';
}

class ApiService {
  static const String _baseUrl = 'http://192.168.100.179:5160/api';
 // Replace with your actual API base URL
  static const _storage = FlutterSecureStorage();
  // static const String _clientToken = 'your-client-token'; // Uncomment and set if required by your API

  /// Wrapper for safe API calls with error handling
  static Future<T> safeApiCall<T>(Future<T> Function() apiCall) async {
    try {
      return await apiCall();
    } on http.ClientException {
      throw ApiException('Network error');
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('An unexpected error occurred');
    }
  }

  /// Sets the authentication token for subsequent API calls
  static Future<void> setAuthToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  /// Gets the authentication token
  static Future<String?> _getAuthToken() async {
    return await _storage.read(key: 'auth_token');
  }

  /// Clears the authentication token for logout
  static Future<void> logout() async {
    try {
      final token = await _getAuthToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/logout'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        await _storage.delete(key: 'auth_token');
        return;
      } else {
        throw ApiException('Failed to logout', statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Failed to connect to the server');
    }
  }

  /// Fetches the parent's profile
  static Future<Map<String, dynamic>> getParentProfile() async {
    try {
      final token = await _getAuthToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/parent/profile'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'fullName': data['fullName'] ?? ''};
      } else if (response.statusCode == 401) {
        throw ApiException('Unauthorized', statusCode: response.statusCode);
      } else {
        throw ApiException('Failed to fetch parent profile', statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Failed to connect to the server');
    }
  }

  /// Fetches the parent's children
  static Future<List<Map<String, dynamic>>> getParentChildren() async {
    try {
      final token = await _getAuthToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/parent/children'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => {
          'id': item['id']?.toString() ?? '',
          'fullName': item['fullName']?.toString() ?? '',
          'grade': item['grade']?.toString() ?? '',
        }).toList();
      } else if (response.statusCode == 401) {
        throw ApiException('Unauthorized', statusCode: response.statusCode);
      } else {
        throw ApiException('Failed to fetch children', statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Failed to connect to the server');
    }
  }

  /// Fetches the admin's profile
  static Future<Map<String, dynamic>> getAdminProfile() async {
    try {
      final token = await _getAuthToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/admin/profile'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'fullName': data['fullName'] ?? ''};
      } else if (response.statusCode == 401) {
        throw ApiException('Unauthorized', statusCode: response.statusCode);
      } else {
        throw ApiException('Failed to fetch admin profile', statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Failed to connect to the server');
    }
  }

  /// Fetches the teacher's profile
  static Future<Map<String, dynamic>> getTeacherProfile() async {
    try {
      final token = await _getAuthToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/teacher/profile'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'fullName': data['fullName'] ?? ''};
      } else if (response.statusCode == 401) {
        throw ApiException('Unauthorized', statusCode: response.statusCode);
      } else {
        throw ApiException('Failed to fetch teacher profile', statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Failed to connect to the server');
    }
  }

  /// Fetches admin dashboard statistics
  static Future<List<Map<String, dynamic>>> getAdminStats() async {
    try {
      final token = await _getAuthToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/admin/stats'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => {
          'label': item['label']?.toString() ?? '',
          'count': item['count'] ?? 0,
          'icon': _mapIcon(item['icon']?.toString() ?? 'default'),
        }).toList();
      } else if (response.statusCode == 401) {
        throw ApiException('Unauthorized', statusCode: response.statusCode);
      } else {
        throw ApiException('Failed to fetch admin stats', statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Failed to connect to the server');
    }
  }

  /// Fetches pickup logs
  static Future<List<dynamic>> getPickupLogs() async {
    try {
      final token = await _getAuthToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/pickup/logs'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => {
          'fullName': item['fullName']?.toString() ?? '',
          'parentName': item['parentName']?.toString() ?? '',
          'verifiedAt': item['verifiedAt']?.toString() ?? '',
          'teacherName': item['teacherName']?.toString() ?? 'Unknown Teacher',
          'timestamp': item['verifiedAt']?.toString() ?? '',
        }).toList();
      } else if (response.statusCode == 401) {
        throw ApiException('Unauthorized', statusCode: response.statusCode);
      } else {
        throw ApiException('Failed to fetch pickup logs', statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Failed to connect to the server');
    }
  }

  /// Verifies a QR code for child pickup
  static Future<Map<String, dynamic>> verifyQRCode(String qrCode) async {
    try {
      final token = await _getAuthToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/qr/verify'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'qrCode': qrCode,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'childName': data['childName'] ?? '',
          'parentName': data['parentName'] ?? '',
          'message': 'Pickup verified for ${data['childName'] ?? 'child'} by ${data['parentName'] ?? 'parent'}',
        };
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['message'] ?? 'Invalid request', statusCode: response.statusCode);
      } else if (response.statusCode == 404) {
        throw ApiException('Invalid QR code', statusCode: response.statusCode);
      } else {
        throw ApiException('Failed to verify QR code', statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Failed to connect to the server');
    }
  }

  /// Generates a QR code for a child
  static Future<Map<String, dynamic>> generateQRCode(String childId) async {
    try {
      final token = await _getAuthToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/qr/generate'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'childId': childId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'qrCode': data['qrCode'] ?? ''};
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['message'] ?? 'Invalid request', statusCode: response.statusCode);
      } else if (response.statusCode == 404) {
        throw ApiException('Invalid child ID', statusCode: response.statusCode);
      } else {
        throw ApiException('Failed to generate QR code', statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Failed to connect to the server');
    }
  }

  /// Registers a new user
  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/register'),
        headers: {
          'Content-Type': 'application/json',
          // if (_clientToken != null) 'Authorization': 'Bearer $_clientToken', // Uncomment if client token is required
        },
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'role': role,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        await setAuthToken(data['token'] ?? '');
        return {
          'token': data['token'] ?? '',
          'emailVerified': data['emailVerified'] ?? false,
        };
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['message'] ?? 'Invalid request', statusCode: response.statusCode);
      } else if (response.statusCode == 409) {
        throw ApiException('Email already exists', statusCode: response.statusCode);
      } else if (response.statusCode == 422) {
        throw ApiException('Invalid role', statusCode: response.statusCode);
      } else {
        throw ApiException('Failed to register', statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Failed to connect to the server');
    }
  }

  /// Logs in a user and returns their role
  static Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
          // if (_clientToken != null) 'Authorization': 'Bearer $_clientToken', // Uncomment if client token is required
        },
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await setAuthToken(data['token'] ?? '');
        return {'role': data['role'] ?? ''};
      } else if (response.statusCode == 401) {
        throw ApiException('Invalid credentials', statusCode: response.statusCode);
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['message'] ?? 'Invalid request', statusCode: response.statusCode);
      } else {
        throw ApiException('Failed to login', statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Failed to connect to the server');
    }
  }

  /// Updates parent details
  static Future<void> updateParent(Map<String, dynamic> parentData) async {
    try {
      final token = await _getAuthToken();
      final response = await http.put(
        Uri.parse('$_baseUrl/parent/update'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(parentData),
      );

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['message'] ?? 'Invalid request', statusCode: response.statusCode);
      } else if (response.statusCode == 409) {
        throw ApiException('Duplicate email', statusCode: response.statusCode);
      } else if (response.statusCode == 422) {
        throw ApiException('Invalid phone number', statusCode: response.statusCode);
      } else {
        throw ApiException('Failed to update parent details', statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Failed to connect to the server');
    }
  }

  /// Creates a new parent
  static Future<void> createParent(Map<String, dynamic> parentData) async {
    try {
      final token = await _getAuthToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/parents'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(parentData),
      );

      if (response.statusCode == 201) {
        return;
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['message'] ?? 'Invalid request', statusCode: response.statusCode);
      } else if (response.statusCode == 409) {
        throw ApiException('Duplicate email', statusCode: response.statusCode);
      } else if (response.statusCode == 422) {
        throw ApiException('Invalid phone number', statusCode: response.statusCode);
      } else {
        throw ApiException('Failed to create parent', statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Failed to connect to the server');
    }
  }

  /// Creates a new teacher
  static Future<void> createTeacher(Map<String, dynamic> teacherData) async {
    try {
      final token = await _getAuthToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/teachers'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(teacherData),
      );

      if (response.statusCode == 201) {
        return;
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['message'] ?? 'Invalid request', statusCode: response.statusCode);
      } else if (response.statusCode == 409) {
        throw ApiException('Duplicate email', statusCode: response.statusCode);
      } else if (response.statusCode == 422) {
        throw ApiException('Invalid phone number', statusCode: response.statusCode);
      } else {
        throw ApiException('Failed to create teacher', statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Failed to connect to the server');
    }
  }
  static Future<void>updateTeacher(Map<String, dynamic> teacherData) async {
    try {
      final token = await _getAuthToken();
      final response = await http.put(
        Uri.parse('$_baseUrl/teachers/update'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(teacherData),
      );

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['message'] ?? 'Invalid request', statusCode: response.statusCode);
      } else if (response.statusCode == 409) {
        throw ApiException('Duplicate email', statusCode: response.statusCode);
      } else if (response.statusCode == 422) {
        throw ApiException('Invalid phone number', statusCode: response.statusCode);
      } else {
        throw ApiException('Failed to update teacher details', statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Failed to connect to the server');
    }
  }

  /// Fetches list of parents
  static Future<List<Map<String, dynamic>>> getParents() async {
    try {
      final token = await _getAuthToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/parents'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['message'] ?? 'Invalid request', statusCode: response.statusCode);
      } else {
        throw ApiException('Failed to fetch parents', statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Failed to connect to the server');
    }
  }

  /// Creates a new child
  static Future<void> createChild(Map<String, dynamic> childData) async {
    try {
      final token = await _getAuthToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/children'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(childData),
      );

      if (response.statusCode == 201) {
        return;
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['message'] ?? 'Invalid request', statusCode: response.statusCode);
      } else if (response.statusCode == 409) {
        throw ApiException('Duplicate child', statusCode: response.statusCode);
      } else if (response.statusCode == 422) {
        throw ApiException('Invalid parent ID', statusCode: response.statusCode);
      } else {
        throw ApiException('Failed to create child', statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Failed to connect to the server');
    }
  }

  /// Maps icon string to IconData
  static IconData _mapIcon(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'person':
        return Icons.person;
      case 'child':
        return Icons.child_care;
      case 'pickup':
        return Icons.directions_car;
      case 'school':
        return Icons.school;
      default:
        return Icons.info;
    }
  }
}