import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  String? _token;
  String? _email;

  bool get isAuthenticated => _isAuthenticated;
  String? get token => _token;
  String? get email => _email;

  Future<void> login(String email, String token) async {
    _isAuthenticated = true;
    _token = token;
    _email = email;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('user_email', email);

    notifyListeners();
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _token = null;
    _email = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_email');

    notifyListeners();
  }

  Future<void> loadStoredAuth() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    _email = prefs.getString('user_email');

    if (_token != null && _email != null) {
      _isAuthenticated = true;
    }

    notifyListeners();
  }
}
