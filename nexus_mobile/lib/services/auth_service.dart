import 'dart:convert';

import 'package:dio/dio.dart';

import '../utils/constants.dart';
import '../utils/error_handler.dart';

class AuthResponse {
  final bool success;
  final String message;
  final String? token;
  final String? refreshToken;

  const AuthResponse({
    required this.success,
    required this.message,
    this.token,
    this.refreshToken,
  });
}

class TokenRefreshResponse {
  final bool success;
  final String? newToken;
  final String? newRefreshToken;

  const TokenRefreshResponse({
    required this.success,
    this.newToken,
    this.newRefreshToken,
  });
}

class AuthService {
  final Dio _dio;

  AuthService() : _dio = Dio(BaseOptions(
    baseUrl: apiUrl,
    connectTimeout: apiTimeout,
    receiveTimeout: apiTimeout,
    headers: {'Content-Type': 'application/json'},
  ));

  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final token = data['access_token'] as String?;
        final refreshToken = data['refresh_token'] as String?;

        if (token == null || token.isEmpty) {
          return const AuthResponse(
            success: false,
            message: 'Resposta invalida do servidor.',
          );
        }

        return AuthResponse(
          success: true,
          message: 'Login realizado com sucesso.',
          token: token,
          refreshToken: refreshToken,
        );
      }

      return AuthResponse(
        success: false,
        message: _extractErrorMessage(response.data, fallback: 'Falha ao realizar login.'),
      );
    } on DioException catch (e) {
      final error = ErrorHandler.handleError(e);
      return AuthResponse(success: false, message: error.userMessage);
    } catch (e) {
      return const AuthResponse(
        success: false,
        message: 'Nao foi possivel conectar ao servidor.',
      );
    }
  }

  Future<AuthResponse> register({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {'email': email, 'password': password, 'username': username},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return const AuthResponse(
          success: true,
          message: 'Cadastro realizado. Faca login para continuar.',
        );
      }

      return AuthResponse(
        success: false,
        message: _extractErrorMessage(response.data, fallback: 'Falha ao realizar cadastro.'),
      );
    } on DioException catch (e) {
      final error = ErrorHandler.handleError(e);
      return AuthResponse(success: false, message: error.userMessage);
    } catch (e) {
      return const AuthResponse(
        success: false,
        message: 'Nao foi possivel conectar ao servidor.',
      );
    }
  }

  Future<TokenRefreshResponse> refreshToken(String currentRefreshToken) async {
    try {
      final response = await _dio.post(
        '/auth/refresh',
        data: {'refresh_token': currentRefreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return TokenRefreshResponse(
          success: true,
          newToken: data['access_token'] as String?,
          newRefreshToken: data['refresh_token'] as String?,
        );
      }

      return const TokenRefreshResponse(success: false);
    } on DioException catch (e) {
      final error = ErrorHandler.handleError(e);
      return TokenRefreshResponse(success: false);
    } catch (e) {
      return const TokenRefreshResponse(success: false);
    }
  }

  Future<AuthResponse> logout(String? token) async {
    try {
      await _dio.post(
        '/auth/logout',
        options: token != null
            ? Options(headers: {'Authorization': 'Bearer $token'})
            : null,
      );
    } catch (e) {
      // Falha silenciosa no logout
    }
    return const AuthResponse(success: true, message: 'Sessao encerrada.');
  }

  String _extractErrorMessage(dynamic data, {required String fallback}) {
    if (data is Map<String, dynamic>) {
      final detail = data['detail'];
      if (detail is String && detail.isNotEmpty) {
        return detail;
      }
      final message = data['message'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }
    return fallback;
  }
}
