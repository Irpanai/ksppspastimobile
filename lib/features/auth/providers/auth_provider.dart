import 'package:flutter/material.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/network/api_client.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus { initial, authenticating, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _token;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get token => _token;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.authenticating;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Check initial auth status on app start (splash / startup)
  Future<void> checkAuthStatus() async {
    final savedToken = await StorageService.getToken();
    if (savedToken == null || savedToken.isEmpty) {
      _status = AuthStatus.unauthenticated;
      _user = null;
      _token = null;
      notifyListeners();
      return;
    }

    _token = savedToken;
    final cachedUser = await StorageService.getUserData();
    if (cachedUser != null) {
      _user = UserModel.fromJson(cachedUser);
    }

    // Try to refresh profile from backend /auth/me
    try {
      final userProfile = await _authService.getProfile();
      _user = userProfile;
      _status = AuthStatus.authenticated;
    } catch (e) {
      // If cached user exists and network failed, we can still stay authenticated or fallback
      if (_user != null) {
        _status = AuthStatus.authenticated;
      } else {
        await StorageService.clearAll();
        _token = null;
        _user = null;
        _status = AuthStatus.unauthenticated;
      }
    }

    notifyListeners();
  }

  /// Login with email and password
  Future<bool> login(String email, String password) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      final loginData = await _authService.login(email: email.trim(), password: password);
      _token = loginData.token;
      _user = loginData.user;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Gagal melakukan login: ${e.toString()}';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Fetch updated profile info from /auth/me
  Future<void> fetchProfile() async {
    try {
      final user = await _authService.getProfile();
      _user = user;
      notifyListeners();
    } catch (_) {
      // Handle silently or update error
    }
  }

  /// Logout and clear state
  Future<void> logout() async {
    _status = AuthStatus.authenticating;
    notifyListeners();

    await _authService.logout();
    _token = null;
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
