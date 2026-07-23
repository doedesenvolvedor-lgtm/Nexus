import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  String? _token;
  String? _refreshToken;
  String? _email;

  final _secureStorage = const FlutterSecureStorage();

  bool get isAuthenticated => _isAuthenticated;
  String? get token => _token;
  String? get refreshToken => _refreshToken;
  String? get email => _email;

  Future<void> login(String email, String token, {String? refreshToken}) async {
    _isAuthenticated = true;
    _token = token;
    _refreshToken = refreshToken;
    _email = email;

    await _secureStorage.write(key: 'auth_token', value: token);
    if (refreshToken != null) {
      await _secureStorage.write(key: 'refresh_token', value: refreshToken);
    }
    await _secureStorage.write(key: 'user_email', value: email);

    notifyListeners();
  }

  Future<void> setTokens({
    required String token,
    required String refreshToken,
  }) async {
    _token = token;
    _refreshToken = refreshToken;
    await _secureStorage.write(key: 'auth_token', value: token);
    await _secureStorage.write(key: 'refresh_token', value: refreshToken);
    notifyListeners();
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _token = null;
    _refreshToken = null;
    _email = null;

    await _secureStorage.delete(key: 'auth_token');
    await _secureStorage.delete(key: 'refresh_token');
    await _secureStorage.delete(key: 'user_email');

    notifyListeners();
  }

  Future<void> loadStoredAuth() async {
    _token = await _secureStorage.read(key: 'auth_token');
    _refreshToken = await _secureStorage.read(key: 'refresh_token');
    _email = await _secureStorage.read(key: 'user_email');

    if (_token != null && _email != null) {
      _isAuthenticated = true;
    }

    notifyListeners();
  }
}
