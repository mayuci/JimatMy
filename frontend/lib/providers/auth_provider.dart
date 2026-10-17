import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._apiService) {
    _apiService.onUnauthorized = _handleUnauthorized;
  }

  static const _tokenKey = 'jimatmy.auth_token';
  final ApiService _apiService;
  SharedPreferences? _preferences;
  AuthUser? user;
  bool isRestoring = true;
  bool isLoading = false;
  String? errorMessage;
  Future<void>? _restoreOperation;
  VoidCallback? onSessionCleared;
  VoidCallback? onSessionStarted;
  int avatarRevision = 0;

  bool get isAuthenticated => user != null && _apiService.hasAuthToken;

  Future<void> restoreSession() async {
    final existing = _restoreOperation;
    if (existing != null) return existing;
    _restoreOperation = _restoreSessionInternal();
    return _restoreOperation;
  }

  Future<void> _restoreSessionInternal() async {
    try {
      _preferences = await SharedPreferences.getInstance();
      final token = _preferences?.getString(_tokenKey);
      if (token == null || token.isEmpty) return;
      _apiService.setAuthToken(token);
      user = await _apiService.getCurrentUser();
      onSessionStarted?.call();
    } on ApiException {
      await _clearSession();
    } finally {
      isRestoring = false;
      notifyListeners();
    }
    _restoreOperation = null;
  }

  Future<String?> login(String email, String password) async {
    return _run(() async {
      final session = await _apiService.login(email, password);
      await _saveSession(session);
    });
  }

  Future<String?> register(String name, String email, String password) async {
    return _run(() async {
      final session = await _apiService.register(name, email, password);
      await _saveSession(session);
    });
  }

  Future<String?> updateName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > 100) {
      return 'Name must be between 1 and 100 characters.';
    }
    if (trimmed == user?.name) return null;
    return _run(() async {
      user = await _apiService.updateCurrentUserName(trimmed);
      notifyListeners();
    });
  }

  Future<String?> selectAvatarPreset(String presetId) => _run(() async {
    user = await _apiService.updateCurrentUser(
      avatarType: 'preset',
      avatarValue: presetId,
    );
    avatarRevision++;
  });

  Future<String?> uploadAvatar(
    Uint8List bytes, {
    required String filename,
    required String mimeType,
  }) => _run(() async {
    user = await _apiService.uploadCurrentUserAvatar(
      bytes,
      filename: filename,
      mimeType: mimeType,
    );
    avatarRevision++;
  });

  Future<String?> removeAvatar() => _run(() async {
    user = await _apiService.removeCurrentUserAvatar();
    avatarRevision++;
  });

  Future<void> logout() async {
    await _clearSession();
    notifyListeners();
  }

  void clearError() {
    if (errorMessage == null) return;
    errorMessage = null;
    notifyListeners();
  }

  Future<String?> _run(Future<void> Function() operation) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await operation();
      return null;
    } on ApiException catch (error) {
      errorMessage = error.message;
      return error.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveSession(AuthSession session) async {
    _apiService.setAuthToken(session.token);
    user = session.user;
    await _preferences?.setString(_tokenKey, session.token);
    onSessionStarted?.call();
  }

  Future<void> _clearSession() async {
    _apiService.clearAuthToken();
    user = null;
    await _preferences?.remove(_tokenKey);
    onSessionCleared?.call();
  }

  void _handleUnauthorized() {
    if (user == null && !_apiService.hasAuthToken) return;
    _apiService.clearAuthToken();
    user = null;
    _preferences?.remove(_tokenKey);
    onSessionCleared?.call();
    notifyListeners();
  }
}
