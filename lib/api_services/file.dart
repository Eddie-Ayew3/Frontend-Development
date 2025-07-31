// lib/api_services/file.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String _baseUrl = 'https://84c4c00a11fb.ngrok-free.app';
  static const _storage = FlutterSecureStorage();

  // Common headers for all requests
  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getAuthToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Wrapper for safe API calls with error handling
  static Future<T> safeApiCall<T>(Future<T> Function() apiCall) async {
    try {
      return await apiCall();
    } on http.ClientException {
      throw ApiException('Network error: Unable to connect to the server', statusCode: -1);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred');
    }
  }

  /// Authentication Token Management
  static Future<void> setAuthToken(String token) async {
    try {
      await _storage.write(key: 'auth_token', value: token);
    } catch (e) {
      throw ApiException('Failed to store authentication token');
    }
  }

  static Future<String?> _getAuthToken() async {
    try {
      return await _storage.read(key: 'auth_token');
    } catch (e) {
      return null;
    }
  }

  static Future<void> clearAuthToken() async {
    try {
      await _storage.delete(key: 'auth_token');
    } catch (e) {
      throw ApiException('Failed to clear authentication token');
    }
  }

  /// Authentication Endpoints
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/v1/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('Login response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData is! Map<String, dynamic>) {
          throw ApiException('Invalid response format');
        }

        final token = responseData['token'] as String?;
        final role = responseData['role'] as String?;
        final userId = responseData['userId']?.toString();

        if (token == null || token.isEmpty) {
          throw ApiException('Authentication token missing');
        }
        if (role == null || role.isEmpty) {
          throw ApiException('User role missing');
        }
        if (userId == null || userId.isEmpty) {
          throw ApiException('User ID missing');
        }

        await setAuthToken(token);
        return {
          'token': token,
          'role': role,
          'userId': userId,
          'message': responseData['message'] ?? 'Login successful',
        };
      } else if (response.statusCode == 401) {
        throw ApiException('Invalid credentials', statusCode: response.statusCode);
      } else if (response.statusCode == 400 || response.statusCode == 422) {
        final errorData = jsonDecode(response.body);
        throw ApiException(
          errorData['message'] ?? 'Invalid request',
          statusCode: response.statusCode,
        );
      } else {
        throw ApiException(
          'Failed to login: ${response.reasonPhrase}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to connect to the server');
    }
  }

  static Future<Map<String, dynamic>> register({
    required String fullname,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/v1/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullname': fullname,
          'email': email,
          'password': password,
          'role': role,
        }),
      );

      print('Register response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        if (responseData is! Map<String, dynamic>) {
          throw ApiException('Invalid response format');
        }

        final token = responseData['token'] as String?;
        final responseRole = responseData['role'] as String?;
        final userId = responseData['userId']?.toString();

        if (token == null || token.isEmpty) {
          throw ApiException('Authentication token missing');
        }
        if (responseRole == null || responseRole.isEmpty) {
          throw ApiException('User role missing');
        }
        if (userId == null || userId.isEmpty) {
          throw ApiException('User ID missing');
        }

        await setAuthToken(token);
        return {
          'token': token,
          'role': responseRole,
          'userId': userId,
          'message': responseData['message'] ?? 'Registration successful',
        };
      } else if (response.statusCode == 400 || response.statusCode == 422) {
        final errorData = jsonDecode(response.body);
        throw ApiException(
          errorData['message'] ?? 'Invalid request',
          statusCode: response.statusCode,
        );
      } else if (response.statusCode == 409) {
        throw ApiException('Email already exists', statusCode: response.statusCode);
      } else {
        throw ApiException(
          'Failed to register: ${response.reasonPhrase}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to connect to the server');
    }
  }

  static Future<void> logout() async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/v1/auth/logout'),
        headers: headers,
      );

      print('Logout response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        await clearAuthToken();
      } else if (response.statusCode == 401) {
        throw ApiException('Unauthorized', statusCode: response.statusCode);
      } else {
        throw ApiException(
          'Failed to logout: ${response.reasonPhrase}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to connect to the server');
    }
  }

  /// User Management Endpoints
  static Future<Map<String, dynamic>> createParent({
    required String fullname,
    required String email,
    required String phone,
    required String location,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/v1/parents'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'fullname': fullname,
          'email': email,
          'phone': phone,
          'location': location,
        }),
      );

      print('Create parent response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        if (responseData is! Map<String, dynamic>) {
          throw ApiException('Invalid response format');
        }
        return {
          'message': responseData['message'] ?? 'Parent created successfully',
          'id': responseData['id']?.toString() ?? 'N/A',
        };
      } else if (response.statusCode == 400 || response.statusCode == 422) {
        final errorData = jsonDecode(response.body);
        throw ApiException(
          errorData['message'] ?? 'Invalid request',
          statusCode: response.statusCode,
        );
      } else if (response.statusCode == 401) {
        throw ApiException('Unauthorized', statusCode: response.statusCode);
      } else if (response.statusCode == 409) {
        throw ApiException('Email already exists', statusCode: response.statusCode);
      } else {
        throw ApiException(
          'Failed to create parent: ${response.reasonPhrase}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to connect to the server');
    }
  }

  static Future<Map<String, dynamic>> createTeacher({
    required String fullname,
    required String email,
    required String phone,
    required String grade,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/v1/teacher'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'fullname': fullname,
          'email': email,
          'phone': phone,
          'grade': grade,
        }),
      );

      print('Create teacher response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        if (responseData is! Map<String, dynamic>) {
          throw ApiException('Invalid response format');
        }
        return {
          'message': responseData['message'] ?? 'Teacher created successfully',
          'id': responseData['id']?.toString() ?? 'N/A',
        };
      } else if (response.statusCode == 400 || response.statusCode == 422) {
        final errorData = jsonDecode(response.body);
        throw ApiException(
          errorData['message'] ?? 'Invalid request',
          statusCode: response.statusCode,
        );
      } else if (response.statusCode == 401) {
        throw ApiException('Unauthorized', statusCode: response.statusCode);
      } else if (response.statusCode == 409) {
        throw ApiException('Email already exists', statusCode: response.statusCode);
      } else {
        throw ApiException(
          'Failed to create teacher: ${response.reasonPhrase}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to connect to the server');
    }
  }

  // Add to api_service.dart
static Future<Map<String, dynamic>> getParentProfile({required String userId}) async {
  try {
    final response = await http.get(
      Uri.parse('$_baseUrl/v1/parents/$userId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 401) {
      throw ApiException('Unauthorized', statusCode: response.statusCode);
    } else if (response.statusCode == 404) {
      throw ApiException('Parent not found', statusCode: response.statusCode);
    } else {
      throw ApiException('Failed to get parent profile', statusCode: response.statusCode);
    }
  } catch (e) {
    if (e is ApiException) rethrow;
    throw ApiException('Failed to connect to the server');
  }
}

static Future<Map<String, dynamic>> updateParent({
  required String userId,
  required String phone,
  required String location,
}) async {
  try {
    final response = await http.put(
      Uri.parse('$_baseUrl/v1/parents/$userId'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'phone': phone,
        'location': location,
      }),
    );

    print('Update Parent Response: ${response.statusCode} - ${response.body}');

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return {
        'success': true,
        'message': responseData['message'] ?? 'Parent updated successfully',
        'parent': {
          'id': responseData['id'],
          'phone': responseData['phone'],
          'location': responseData['location'],
        }
      };
    } else if (response.statusCode == 400) {
      final errorData = jsonDecode(response.body);
      throw ApiException(
        errorData['message'] ?? 'Invalid request data',
        statusCode: response.statusCode,
      );
    } else if (response.statusCode == 401) {
      throw ApiException('Unauthorized - please login again', 
        statusCode: response.statusCode);
    } else if (response.statusCode == 403) {
      throw ApiException('You can only update your own profile', 
        statusCode: response.statusCode);
    } else if (response.statusCode == 404) {
      throw ApiException('Parent profile not found', 
        statusCode: response.statusCode);
    } else {
      throw ApiException(
        'Failed to update parent: ${response.reasonPhrase}',
        statusCode: response.statusCode,
      );
    }
  } on http.ClientException {
    throw ApiException('Network error - please check your connection');
  } catch (e) {
    throw ApiException('An unexpected error occurred: ${e.toString()}');
  }
}

static Future<Map<String, dynamic>> getTeacherProfile({required String userId}) async {
  try {
    final response = await http.get(
      Uri.parse('$_baseUrl/v1/teacher/$userId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 401) {
      throw ApiException('Unauthorized', statusCode: response.statusCode);
    } else if (response.statusCode == 404) {
      throw ApiException('Teacher not found', statusCode: response.statusCode);
    } else {
      throw ApiException('Failed to get teacher profile', statusCode: response.statusCode);
    }
  } catch (e) {
    if (e is ApiException) rethrow;
    throw ApiException('Failed to connect to the server');
  }
}

static Future<Map<String, dynamic>> updateTeacher({
  required String userId,
  required String phone,
  required String grade,
}) async {
  try {
    final response = await http.put(
      Uri.parse('$_baseUrl/v1/teacher/$userId'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'phone': phone,
        'grade': grade,
      }),
    );

    print('Update Parent Response: ${response.statusCode} - ${response.body}');

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return {
        'success': true,
        'message': responseData['message'] ?? 'Parent updated successfully',
        'parent': {
          'id': responseData['id'],
          'phone': responseData['phone'],
          'location': responseData['location'],
        }
      };
    } else if (response.statusCode == 400) {
      final errorData = jsonDecode(response.body);
      throw ApiException(
        errorData['message'] ?? 'Invalid request data',
        statusCode: response.statusCode,
      );
    } else if (response.statusCode == 401) {
      throw ApiException('Unauthorized - please login again', 
        statusCode: response.statusCode);
    } else if (response.statusCode == 403) {
      throw ApiException('You can only update your own profile', 
        statusCode: response.statusCode);
    } else if (response.statusCode == 404) {
      throw ApiException('Parent profile not found', 
        statusCode: response.statusCode);
    } else {
      throw ApiException(
        'Failed to update parent: ${response.reasonPhrase}',
        statusCode: response.statusCode,
      );
    }
  } on http.ClientException {
    throw ApiException('Network error - please check your connection');
  } catch (e) {
    throw ApiException('An unexpected error occurred: ${e.toString()}');
  }
}

}
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException: $message${statusCode != null ? ' (Status Code: $statusCode)' : ''}';
}