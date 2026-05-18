import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/desktop_config.dart';
import '../models/auth_user.dart';

class AuthStore {
  AuthStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'desktop_api_token';
  static const _userNameKey = 'desktop_user_name';
  static const _userEmailKey = 'desktop_user_email';
  static const _userIdKey = 'desktop_user_id';
  static const _apiBaseUrlKey = 'desktop_api_base_url';

  final FlutterSecureStorage _storage;

  String? _token;
  AuthUser? _user;
  String? _apiBaseUrl;

  String? get token => _token;
  AuthUser? get user => _user;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  Future<void> load() async {
    _token = await _storage.read(key: _tokenKey);
    final userId = await _storage.read(key: _userIdKey);
    final name = await _storage.read(key: _userNameKey);
    final email = await _storage.read(key: _userEmailKey);
    _apiBaseUrl = await _storage.read(key: _apiBaseUrlKey);

    if (userId != null && name != null && email != null) {
      _user = AuthUser(
        id: int.parse(userId),
        name: name,
        email: email,
      );
    } else {
      _user = null;
    }
  }

  String apiBaseUrl() {
    return DesktopConfig.normalizeBaseUrl(
      _apiBaseUrl ?? DesktopConfig.apiBaseUrlFromEnvironment(),
    );
  }

  Future<void> saveSession(LoginResult result) async {
    _token = result.token;
    _user = result.user;
    await _storage.write(key: _tokenKey, value: result.token);
    await _storage.write(key: _userIdKey, value: result.user.id.toString());
    await _storage.write(key: _userNameKey, value: result.user.name);
    await _storage.write(key: _userEmailKey, value: result.user.email);
  }

  Future<void> saveApiBaseUrl(String url) async {
    final normalized = DesktopConfig.normalizeBaseUrl(url);
    _apiBaseUrl = normalized;
    await _storage.write(key: _apiBaseUrlKey, value: normalized);
  }

  Future<void> clearSession() async {
    _token = null;
    _user = null;
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _userNameKey);
    await _storage.delete(key: _userEmailKey);
  }
}
