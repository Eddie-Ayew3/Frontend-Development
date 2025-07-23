// lib/api_services/file.dart
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
  static const String _baseUrl = 'https://a59ac265fef1.ngrok-free.app/v1'; // Updated to match ngrok URL
  static const _storage = FlutterSecureStorage();

  // Common headers for all requests
  static Map<String, String> _getHeaders(String? token) => {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true', // Bypass ngrok warning for free tier
        if (token != null) 'Authorization': 'Bearer $token',
      };

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

  /// Sets the authentication token
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
        Uri.parse('$_baseUrl/auth/logout'), // Adjusted path
        headers: _getHeaders(token),
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
        Uri.parse('$_baseUrl/parent/profile'), // Adjusted path
        headers: _getHeaders(token),
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
        Uri.parse('$_baseUrl/parent/children'), // Adjusted path
        headers: _getHeaders(token),
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
        Uri.parse('$_baseUrl/admin/profile'), // Adjusted path
        headers: _getHeaders(token),
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
        Uri.parse('$_baseUrl/teacher/profile'), // Adjusted path
        headers: _getHeaders(token),
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
        Uri.parse('$_baseUrl/admin/stats'), // Adjusted path
        headers: _getHeaders(token),
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
        Uri.parse('$_baseUrl/pickup/logs'), // Adjusted path
        headers: _getHeaders(token),
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
        Uri.parse('$_baseUrl/qr/verify'), // Adjusted path
        headers: _getHeaders(token),
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

// lib/api_services/file.dart (partial update)
static Future<Map<String, dynamic>> getChildren() async {
  try {
    final token = await _getAuthToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/children'), // Matches /v1/children for parent’s children
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {'children': data['children'] ?? []}; // Adjust based on backend response
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

static Future<Map<String, dynamic>> generateQRCode(int childId) async {
  try {
    final token = await _getAuthToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/children/generate?childId=$childId'), // Matches /v1/children/generate
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {'qrCode': data['qrCode'] ?? ''};
    } else if (response.statusCode == 400) {
      final errorData = jsonDecode(response.body);
      throw ApiException(errorData['message'] ?? 'Invalid request', statusCode: response.statusCode);
    } else if (response.statusCode == 500) {
      throw ApiException('Failed to generate QR code', statusCode: response.statusCode);
    } else {
      throw ApiException('Unexpected error', statusCode: response.statusCode);
    }
  } catch (e) {
    if (e is ApiException) {
      rethrow;
    }
    throw ApiException('Failed to connect to the server');
  }
}
  /// Generates a QR code for a child

  /// Registers a new user
  static Future<Map<String, dynamic>> register({
    required String fullname,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'), // Adjusted path
        headers: _getHeaders(null),
        body: jsonEncode({
          'fullname': fullname,
          'email': email,
          'role': role,
          'password': password,
          
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        await setAuthToken(data['token'] ?? '');
        return {
          'token': data['token'] ?? '',
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
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'), // Matches your example
        headers: _getHeaders(null),
        body: jsonEncode({
          'email': email,
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
  static Future<void> updateParent({
    required String phone,
    required String location,
  }) async {
    try {
      final token = await _getAuthToken();
      final response = await http.put(
        Uri.parse('$_baseUrl/parent/update'), // Adjusted path
        headers: _getHeaders(token),
        body: jsonEncode({
          'phone': phone,
          'location': location,
        }),
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
  static Future<void> createParent({
    required String fullname,
    required String email,
    required String phone,
    required String location,
  }) async {
    try {
      final token = await _getAuthToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/parents'), // Adjusted path
        headers: _getHeaders(token),
        body: jsonEncode(
          {
            'fullname': fullname,
            'email': email,
            'phone': phone,
            'location': location,
          },
        ),
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
  static Future<void> createTeacher({
    required String fullname,
    required String email,
    required String phone,
    required String grade,
  }

  ) async {
    try {
      final token = await _getAuthToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/teachers'), // Adjusted path
        headers: _getHeaders(token),
        body: jsonEncode({
          'fullname': fullname,
          'email': email,
          'phone': phone,
          'grade': grade,
        }),
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

  /// Updates teacher details
  static Future<void> updateTeacher({required String phone, required String grade}) async {
    try {
      final token = await _getAuthToken();
      final response = await http.put(
        Uri.parse('$_baseUrl/teachers/update'), // Adjusted path
        headers: _getHeaders(token),
        body: jsonEncode({
          'phone': phone,
          'grade': grade,
        }),
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
        Uri.parse('$_baseUrl/parents'), // Adjusted path
        headers: _getHeaders(token),
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
  static Future<void> createChild({
    required String fullName,
    required String grade,
    required String gender,
    required int parentId,
  }) async {
    try {
      // Retrieve the authentication token from secure storage
      final token = await _getAuthToken();
      // Send POST request to create a new child
      final response = await http.post(
        Uri.parse('$_baseUrl/children'), // API endpoint for creating children
        headers: _getHeaders(token),     // Include auth headers
        body: jsonEncode({
          'fullName': fullName,          // Child's full name
          'grade': grade,                // Child's grade
          'gender': gender,              // Child's gender
          'parentId': parentId,          // Associated parent ID
        }),
      );

      // Handle response status codes
      if (response.statusCode == 201) {
        // Child created successfully
        return;
      } else if (response.statusCode == 400) {
        // Bad request, show server error message if available
        final errorData = jsonDecode(response.body);
        throw ApiException(errorData['message'] ?? 'Invalid request', statusCode: response.statusCode);
      } else if (response.statusCode == 409) {
        // Child already exists
        throw ApiException('Child Already exists', statusCode: response.statusCode);
      } else if (response.statusCode == 422) {
        // Invalid data provided
        throw ApiException('Invalid Data', statusCode: response.statusCode);
      } else {
        // Other errors
        throw ApiException('Failed to create child', statusCode: response.statusCode);
      }
    } catch (e) {
      // Rethrow known API exceptions, otherwise throw a generic error
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