import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:developer' as developer;

/// Tipos de erro da aplicação
enum ErrorType {
  network,        // Erro de conexão
  timeout,        // Timeout de requisição
  badRequest,     // 400 - Requisição inválida
  unauthorized,   // 401 - Não autorizado
  forbidden,      // 403 - Acesso proibido
  notFound,       // 404 - Não encontrado
  conflict,       // 409 - Conflito
  rateLimit,      // 429 - Rate limit excedido
  serverError,    // 500+ - Erro no servidor
  unknown,        // Erro desconhecido
}

/// Classe para representar erros estruturados
class AppException implements Exception {
  final String message;
  final ErrorType type;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;
  final int? statusCode;

  AppException({
    required this.message,
    required this.type,
    this.code,
    this.originalError,
    this.stackTrace,
    this.statusCode,
  });

  @override
  String toString() => message;

  /// Retorna mensagem amigável ao usuário
  String get userMessage {
    switch (type) {
      case ErrorType.network:
        return 'Erro de conexão. Verifique sua internet.';
      case ErrorType.timeout:
        return 'Requisição expirada. Tente novamente.';
      case ErrorType.unauthorized:
        return 'Sessão expirada. Faça login novamente.';
      case ErrorType.forbidden:
        return 'Acesso negado. Você não tem permissão.';
      case ErrorType.notFound:
        return 'Recurso não encontrado.';
      case ErrorType.conflict:
        return 'Conflito ao processar requisição.';
      case ErrorType.rateLimit:
        return 'Muitas requisições. Aguarde um momento.';
      case ErrorType.badRequest:
        return message; // Mensagem específica do servidor
      case ErrorType.serverError:
        return 'Erro no servidor. Tente novamente mais tarde.';
      case ErrorType.unknown:
        return 'Erro desconhecido. Tente novamente.';
    }
  }

  /// Log estruturado do erro
  void log() {
    developer.log(
      message,
      name: 'AppException',
      error: originalError,
      stackTrace: stackTrace,
      level: 1000, // ERROR level
    );
  }
}

/// Handler centralizado de erros
class ErrorHandler {
  static const String _logPrefix = '🔴 [ErrorHandler]';

  /// Converte exceções em AppException
  static AppException handleError(dynamic error, [StackTrace? stackTrace]) {
    debugPrint('$_logPrefix Processando erro: ${error.runtimeType}');

    if (error is AppException) {
      return error;
    }

    if (error is DioException) {
      return _handleDioException(error, stackTrace);
    }

    if (error is FormatException) {
      return AppException(
        message: 'Formato de dados inválido',
        type: ErrorType.badRequest,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    return AppException(
      message: error.toString(),
      type: ErrorType.unknown,
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// Handler específico para erros Dio (HTTP)
  static AppException _handleDioException(DioException error, [StackTrace? stackTrace]) {
    debugPrint('$_logPrefix DioException Type: ${error.type}');

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AppException(
          message: 'Conexão expirada. Tente novamente.',
          type: ErrorType.timeout,
          originalError: error,
          stackTrace: stackTrace,
          statusCode: error.response?.statusCode,
        );

      case DioExceptionType.connectionError:
        return AppException(
          message: 'Erro de conexão.',
          type: ErrorType.network,
          originalError: error,
          stackTrace: stackTrace,
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 0;
        final responseData = error.response?.data;

        String message = 'Erro desconhecido';
        ErrorType errorType = ErrorType.serverError;

        // Tenta extrair mensagem do servidor
        if (responseData is Map<String, dynamic>) {
          message = responseData['detail'] ?? 
                   responseData['message'] ?? 
                   responseData['error'] ?? 
                   'Erro no servidor';
        }

        // Mapeia status codes para tipos
        switch (statusCode) {
          case 400:
            errorType = ErrorType.badRequest;
            break;
          case 401:
            errorType = ErrorType.unauthorized;
            break;
          case 403:
            errorType = ErrorType.forbidden;
            break;
          case 404:
            errorType = ErrorType.notFound;
            break;
          case 409:
            errorType = ErrorType.conflict;
            break;
          case 429:
            errorType = ErrorType.rateLimit;
            message = 'Muitas requisições. Aguarde alguns segundos.';
            break;
          default:
            if (statusCode >= 500) {
              errorType = ErrorType.serverError;
            }
        }

        return AppException(
          message: message,
          type: errorType,
          code: statusCode.toString(),
          originalError: error,
          stackTrace: stackTrace,
          statusCode: statusCode,
        );

      case DioExceptionType.cancel:
        return AppException(
          message: 'Requisição cancelada.',
          type: ErrorType.unknown,
          originalError: error,
          stackTrace: stackTrace,
        );

      case DioExceptionType.unknown:
        return AppException(
          message: 'Erro desconhecido ao conectar.',
          type: ErrorType.unknown,
          originalError: error,
          stackTrace: stackTrace,
        );

      default:
        return AppException(
          message: 'Erro não mapeado: ${error.type}',
          type: ErrorType.unknown,
          originalError: error,
          stackTrace: stackTrace,
        );
    }
  }

  /// Exibe diálogo de erro ao usuário
  static Future<void> showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    String? actionLabel = 'OK',
    VoidCallback? onAction,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 12),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onAction?.call();
            },
            child: Text(actionLabel ?? 'OK'),
          ),
        ],
      ),
    );
  }

  /// Exibe snackbar de erro
  static void showErrorSnackBar(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Retry automático com backoff exponencial
  static Future<T> retryWithBackoff<T>({
    required Future<T> Function() fn,
    int maxRetries = 3,
    Duration initialDelay = const Duration(milliseconds: 500),
  }) async {
    int retryCount = 0;
    Duration delay = initialDelay;

    while (true) {
      try {
        return await fn();
      } catch (e) {
        retryCount++;
        if (retryCount >= maxRetries) rethrow;

        debugPrint('$_logPrefix Tentativa $retryCount falhou. Aguardando $delay...');
        await Future.delayed(delay);
        delay *= 2; // Backoff exponencial
      }
    }
  }
}

/// Extension para context - facilita acesso a ErrorHandler
extension ErrorHandlerExtension on BuildContext {
  void showError(String message) {
    ErrorHandler.showErrorSnackBar(this, message: message);
  }

  Future<void> showErrorDialog(
    String title,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return ErrorHandler.showErrorDialog(
      this,
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}
