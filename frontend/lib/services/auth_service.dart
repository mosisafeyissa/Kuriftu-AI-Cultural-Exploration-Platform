import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'platform_config.dart';

class AuthService {
  /// Base URL for auth endpoints: e.g. http://localhost:8000/api/auth
  static String get _authUrl {
    final base = getBaseUrl(); // ends with /api
    return '$base/auth';
  }

  static const _accessTokenKey = 'auth_access_token';
  static const _refreshTokenKey = 'auth_refresh_token';
  static const _userKey = 'auth_user';

  // ── Token Storage ────────────────────────────────────────────────────────

  static Future<void> saveTokens(String access, String refresh) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, access);
    await prefs.setString(_refreshTokenKey, refresh);
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  static Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  static Future<User?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson == null) return null;
    try {
      return User.fromJson(jsonDecode(userJson));
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userKey);
  }

  // ── Auth Header ──────────────────────────────────────────────────────────

  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── Register ─────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String passwordConfirm,
    String fullName = '',
    String phone = '',
  }) async {
    try {
      debugPrint('[AuthService] POST $_authUrl/register/');
      final response = await http.post(
        Uri.parse('$_authUrl/register/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'password_confirm': passwordConfirm,
          'full_name': fullName,
          'phone': phone,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        final tokens = data['tokens'];
        await saveTokens(tokens['access'], tokens['refresh']);
        final user = User.fromJson(data['user']);
        await saveUser(user);
        return {'success': true, 'user': user};
      }

      return {'success': false, 'error': _parseError(data)};
    } catch (e) {
      debugPrint('[AuthService] Register error: $e');
      return {'success': false, 'error': _networkError(e)};
    }
  }

  // ── Login ────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('[AuthService] POST $_authUrl/login/');
      final response = await http.post(
        Uri.parse('$_authUrl/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final tokens = data['tokens'];
        await saveTokens(tokens['access'], tokens['refresh']);
        final user = User.fromJson(data['user']);
        await saveUser(user);
        return {'success': true, 'user': user};
      }

      return {'success': false, 'error': _parseError(data)};
    } catch (e) {
      debugPrint('[AuthService] Login error: $e');
      return {'success': false, 'error': _networkError(e)};
    }
  }

  // ── Get Profile ──────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final headers = await getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_authUrl/profile/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final user = User.fromJson(jsonDecode(response.body));
        await saveUser(user);
        return {'success': true, 'user': user};
      }

      if (response.statusCode == 401) {
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          return getProfile();
        }
        return {'success': false, 'error': 'Session expired. Please log in again.'};
      }

      return {'success': false, 'error': 'Failed to load profile.'};
    } catch (e) {
      debugPrint('[AuthService] Profile error: $e');
      return {'success': false, 'error': _networkError(e)};
    }
  }

  // ── Update Profile ───────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? phone,
  }) async {
    try {
      final headers = await getAuthHeaders();
      final body = <String, dynamic>{};
      if (fullName != null) body['full_name'] = fullName;
      if (phone != null) body['phone'] = phone;

      final response = await http.put(
        Uri.parse('$_authUrl/profile/'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final user = User.fromJson(jsonDecode(response.body));
        await saveUser(user);
        return {'success': true, 'user': user};
      }

      return {'success': false, 'error': 'Failed to update profile.'};
    } catch (e) {
      debugPrint('[AuthService] Update profile error: $e');
      return {'success': false, 'error': _networkError(e)};
    }
  }

  // ── Change Password ──────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
    required String newPasswordConfirm,
  }) async {
    try {
      final headers = await getAuthHeaders();
      final response = await http.post(
        Uri.parse('$_authUrl/change-password/'),
        headers: headers,
        body: jsonEncode({
          'old_password': oldPassword,
          'new_password': newPassword,
          'new_password_confirm': newPasswordConfirm,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final tokens = data['tokens'];
        if (tokens != null) {
          await saveTokens(tokens['access'], tokens['refresh']);
        }
        return {'success': true, 'message': data['detail'] ?? 'Password changed.'};
      }

      return {'success': false, 'error': _parseError(data)};
    } catch (e) {
      debugPrint('[AuthService] Change password error: $e');
      return {'success': false, 'error': _networkError(e)};
    }
  }

  // ── Token Refresh ────────────────────────────────────────────────────────

  static Future<bool> refreshAccessToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) return false;

      final response = await http.post(
        Uri.parse('$_authUrl/token/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccess = data['access'] as String;
        final newRefresh = data['refresh'] as String? ?? refreshToken;
        await saveTokens(newAccess, newRefresh);
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('[AuthService] Token refresh error: $e');
      return false;
    }
  }

  // ── Logout ───────────────────────────────────────────────────────────────

  static Future<void> logout() async {
    await clearAll();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  static String _parseError(dynamic data) {
    if (data is Map) {
      final nonField = data['non_field_errors'];
      if (nonField is List && nonField.isNotEmpty) return nonField.first.toString();

      final detail = data['detail'];
      if (detail != null) return detail.toString();

      for (final entry in data.entries) {
        if (entry.value is List && (entry.value as List).isNotEmpty) {
          return '${entry.key}: ${(entry.value as List).first}';
        }
        if (entry.value is String) {
          return '${entry.key}: ${entry.value}';
        }
      }
    }
    return 'An unexpected error occurred.';
  }

  static String _networkError(dynamic e) {
    final msg = e.toString();
    if (msg.contains('SocketException') ||
        msg.contains('Connection refused') ||
        msg.contains('XMLHttpRequest')) {
      return 'Network error: Unable to reach the server.';
    }
    return 'Something went wrong. Please try again.';
  }
}
