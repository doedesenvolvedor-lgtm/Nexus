import 'dart:convert';

import 'package:http/http.dart' as http;

import '../utils/constants.dart';

class AuthResponse {
  final bool success;
  final String message;
  final String? token;

  const AuthResponse({
    required this.success,
    required this.message,
    this.token,
  });
}

class AuthService {
  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = _decodeBody(response.body);
      if (response.statusCode == 200) {
        final token = data['access_token'] as String?;
        if (token == null || token.isEmpty) {
          return const AuthResponse(
            success: false,
            message: 'Resposta inválida do servidor.',
          );
        }

        return const AuthResponse(
          success: true,
          message: 'Login realizado com sucesso.',
        ).copyWith(token: token);
      }

      return AuthResponse(
        success: false,
        message: _extractErrorMessage(data, fallback: 'Falha ao realizar login.'),
      );
    } catch (_) {
      return const AuthResponse(
        success: false,
        message: 'Não foi possível conectar ao servidor.',
      );
    }
  }

  Future<AuthResponse> register({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'username': username,
        }),
      );

      final data = _decodeBody(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return const AuthResponse(
          success: true,
          message: 'Cadastro realizado. Faça login para continuar.',
        );
      }

      return AuthResponse(
        success: false,
        message: _extractErrorMessage(data, fallback: 'Falha ao realizar cadastro.'),
      );
    } catch (_) {
      return const AuthResponse(
        success: false,
        message: 'Não foi possível conectar ao servidor.',
      );
    }
  }

  Map<String, dynamic> _decodeBody(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      // Ignora parsing inválido e retorna mapa vazio.
    }
    return {};
  }

  String _extractErrorMessage(Map<String, dynamic> data, {required String fallback}) {
    final detail = data['detail'];
    if (detail is String && detail.isNotEmpty) {
      return detail;
    }

    final message = data['message'];
    if (message is String && message.isNotEmpty) {
      return message;
    }

    return fallback;
  }
}

extension on AuthResponse {
  AuthResponse copyWith({
    bool? success,
    String? message,
    String? token,
  }) {
    return AuthResponse(
      success: success ?? this.success,
      message: message ?? this.message,
      token: token ?? this.token,
    );
  }
}
