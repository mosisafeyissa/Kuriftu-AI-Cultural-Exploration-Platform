import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.unknown;
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  AuthStatus get status => _status;
  User? get user => _user;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _tryAutoLogin();
  }

  // ── Auto-login from stored token ──────────────────────────────────────────

  Future<void> _tryAutoLogin() async {
    final token = await AuthService.getAccessToken();
    if (token == null) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    // We have a saved token; try loading the stored user first (fast)
    _user = await AuthService.getSavedUser();
    if (_user != null) {
      _status = AuthStatus.authenticated;
      notifyListeners();
    }

    // Then refresh profile in background
    final result = await AuthService.getProfile();
    if (result['success'] == true) {
      _user = result['user'] as User;
      _status = AuthStatus.authenticated;
    } else {
      // Token may have expired
      _user = null;
      _status = AuthStatus.unauthenticated;
      await AuthService.clearAll();
    }
    notifyListeners();
  }

  // ── Register ──────────────────────────────────────────────────────────────

  Future<bool> register({
    required String email,
    required String password,
    required String passwordConfirm,
    String fullName = '',
    String phone = '',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await AuthService.register(
      email: email,
      password: password,
      passwordConfirm: passwordConfirm,
      fullName: fullName,
      phone: phone,
    );

    _isLoading = false;

    if (result['success'] == true) {
      _user = result['user'] as User;
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    }

    _errorMessage = result['error'] as String?;
    notifyListeners();
    return false;
  }

  // ── Login ─────────────────────────────────────────────────────────────────

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await AuthService.login(
      email: email,
      password: password,
    );

    _isLoading = false;

    if (result['success'] == true) {
      _user = result['user'] as User;
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    }

    _errorMessage = result['error'] as String?;
    notifyListeners();
    return false;
  }

  // ── Update Profile ────────────────────────────────────────────────────────

  Future<bool> updateProfile({String? fullName, String? phone}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await AuthService.updateProfile(
      fullName: fullName,
      phone: phone,
    );

    _isLoading = false;

    if (result['success'] == true) {
      _user = result['user'] as User;
      notifyListeners();
      return true;
    }

    _errorMessage = result['error'] as String?;
    notifyListeners();
    return false;
  }

  // ── Change Password ──────────────────────────────────────────────────────

  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
    required String newPasswordConfirm,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await AuthService.changePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
      newPasswordConfirm: newPasswordConfirm,
    );

    _isLoading = false;

    if (result['success'] == true) {
      _errorMessage = null;
      notifyListeners();
      return true;
    }

    _errorMessage = result['error'] as String?;
    notifyListeners();
    return false;
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await AuthService.logout();
    _user = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
