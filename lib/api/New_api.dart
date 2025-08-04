import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
  static const String _baseUrl = 'https://ee514dc30027.ngrok-free.app/v1';
  static const Duration _timeoutDuration = Duration(seconds: 30);
  static const Duration _tokenExpirationThreshold = Duration(minutes: 5);
  static const _storage = FlutterSecureStorage();

  // Keys for secure storage
  static const _tokenKey = 'auth_token';
  static const _emailKey = 'user_email';
  static const _fullnameKey = 'user_fullname';
  static const _roleKey = 'user_role';
  static const _roleIdKey = 'user_roleId';
  static const _expirationKey = 'token_expiration';

  static Future<dynamic> safeApiCall(Future<dynamic> Function() apiCall) async {
    try {
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

  // User data management
  static Future<void> setUserData({
    required String token,
    required String email,
    required String fullname,
    required String role,
    required String roleId,
    required String expiration,
  }) async {
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
    return {
      'token': await _storage.read(key: _tokenKey),
      'email': await _storage.read(key: _emailKey),
      'fullname': await _storage.read(key: _fullnameKey),
      'role': await _storage.read(key: _roleKey),
      'roleId': await _storage.read(key: _roleIdKey),
      'expiration': await _storage.read(key: _expirationKey),
    };
  }

  static Future<String?> getAuthToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<void> clearUserData() async {
    await _storage.deleteAll();
  }

  static bool _isTokenExpired(String? expiration) {
    if (expiration == null) return true;
    try {
      final expirationDate = DateTime.parse(expiration).toUtc();
      final now = DateTime.now().toUtc();
      return expirationDate.isBefore(now.add(_tokenExpirationThreshold));
    } catch (e) {
      return true;
    }
  }

  static Future<Map<String, dynamic>?> checkAuthStatus() async {
    final userData = await getUserData();
    final token = userData['token'];
    final expiration = userData['expiration'];

    if (token == null) return null;

    if (_isTokenExpired(expiration)) {
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
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);
    
    if (response.statusCode == 200) {
      final newToken = data['token'];
      final newExpiration = data['expiration'] ?? 
          DateTime.now().toUtc().add(const Duration(days: 1)).toIso8601String();
      
      if (newToken != null) {
        // Update only token and expiration
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
    final url = Uri.parse('$_baseUrl/auth/login');
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
  }

  static Future<Map<String, dynamic>> register({
    required String fullname,
    required String email,
    required String password,
    required String role,
  }) async {
    final url = Uri.parse('$_baseUrl/auth/register');
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
    
    if (response.statusCode == 200) {
      return {
        'message': data['message'],
        'id': data['id'].toString(),
        'role': role,
      };
    }
    throw ApiException(
      data['message'] ?? 'Registration failed',
      response.statusCode,
    );
  }

  // Logout a user
  static Future<void> logout() async {
    await safeApiCall(() async {
      // Get current token before clearing data
      final token = await getAuthToken();
      
      // Clear local user data immediately (whether server logout succeeds or not)
      await clearUserData();

      // If no token exists, consider logout successful (idempotent operation)
      if (token == null) return;

      final url = Uri.parse('$_baseUrl/auth/logout');
      final response = await http.post(
        url,
        headers: {
          'accept': '*/*',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));

      // Consider any 2xx status code as successful logout
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return;
      }

      // Parse error response if available
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