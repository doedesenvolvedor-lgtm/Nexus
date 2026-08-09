import 'package:dio/dio.dart';

import '../utils/constants.dart';

/// Modelo de configurações de Controle Parental (espelho do backend).
class ParentalSettings {
  final String profileId;
  final String maxRating;
  final int dailyTimeLimitMinutes;
  final String allowedStartTime;
  final String allowedEndTime;
  final bool hideAdultContent;
  final bool lockedByPin;
  final bool biometricEnabled;
  final int requireAuthAfterMinutes;
  final bool blockAdultChannels;
  final bool hasPin;

  ParentalSettings({
    required this.profileId,
    required this.maxRating,
    required this.dailyTimeLimitMinutes,
    required this.allowedStartTime,
    required this.allowedEndTime,
    required this.hideAdultContent,
    required this.lockedByPin,
    required this.biometricEnabled,
    required this.requireAuthAfterMinutes,
    required this.blockAdultChannels,
    required this.hasPin,
  });

  factory ParentalSettings.fromJson(Map<String, dynamic> json) {
    return ParentalSettings(
      profileId: json['profile_id'] ?? '',
      maxRating: json['max_rating'] ?? '18',
      dailyTimeLimitMinutes: json['daily_time_limit_minutes'] ?? 0,
      allowedStartTime: json['allowed_start_time'] ?? '00:00',
      allowedEndTime: json['allowed_end_time'] ?? '23:59',
      hideAdultContent: json['hide_adult_content'] ?? true,
      lockedByPin: json['locked_by_pin'] ?? true,
      biometricEnabled: json['biometric_enabled'] ?? false,
      requireAuthAfterMinutes: json['require_auth_after_minutes'] ?? 30,
      blockAdultChannels: json['block_adult_channels'] ?? true,
      hasPin: json['has_pin'] ?? false,
    );
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'max_rating': maxRating,
      'daily_time_limit_minutes': dailyTimeLimitMinutes,
      'allowed_start_time': allowedStartTime,
      'allowed_end_time': allowedEndTime,
      'hide_adult_content': hideAdultContent,
      'locked_by_pin': lockedByPin,
      'biometric_enabled': biometricEnabled,
      'require_auth_after_minutes': requireAuthAfterMinutes,
      'block_adult_channels': blockAdultChannels,
    };
  }
}

/// Resultado de uma verificação de acesso (decisão centralizada no backend).
class AccessDecision {
  final bool allowed;
  final String? message;
  final String reason;

  AccessDecision({required this.allowed, this.message, this.reason = ''});

  factory AccessDecision.fromJson(Map<String, dynamic> json) {
    return AccessDecision(
      allowed: json['allowed'] ?? false,
      message: json['message'],
      reason: json['reason'] ?? '',
    );
  }
}

class ParentalControlService {
  final Dio _dio;

  ParentalControlService({String? token})
      : _dio = Dio(BaseOptions(
          baseUrl: apiUrl,
          connectTimeout: apiTimeout,
          receiveTimeout: apiTimeout,
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ));

  void setToken(String? token) {
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    } else {
      _dio.options.headers.remove('Authorization');
    }
  }

  /// Obtém as configurações de controle parental de um perfil.
  Future<ParentalSettings?> getSettings(String profileId) async {
    try {
      final response = await _dio.get('/parental/settings/$profileId');
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return ParentalSettings.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  /// Atualiza as configurações de controle parental.
  Future<bool> updateSettings(String profileId, ParentalSettings settings) async {
    try {
      final response = await _dio.put(
        '/parental/settings/$profileId',
        data: settings.toUpdateJson(),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Define ou altera o PIN (armazenado com hash bcrypt no backend).
  Future<bool> setPin(String profileId, String pin) async {
    try {
      final response = await _dio.post(
        '/parental/pin/$profileId',
        data: {'pin': pin},
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Verifica o PIN informado.
  Future<bool> verifyPin(String profileId, String pin) async {
    try {
      final response = await _dio.post(
        '/parental/pin/$profileId/verify',
        data: {'pin': pin},
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Desbloqueia conteúdo +18 após verificar o PIN.
  Future<bool> unlockContent(String profileId, String pin) async {
    try {
      final response = await _dio.post(
        '/parental/pin/$profileId/unlock',
        data: {'pin': pin},
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Verifica centralizadamente o acesso a um conteúdo (enforcement backend).
  Future<AccessDecision> checkAccess({
    required String profileId,
    required String contentType,
    String? targetId,
    String? rating,
    String? title,
  }) async {
    try {
      final response = await _dio.post(
        '/parental/check-access',
        data: {
          'profile_id': profileId,
          'content_type': contentType,
          'target_id': targetId,
          'rating': rating,
          'title': title,
        },
      );
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return AccessDecision.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (_) {}
    return AccessDecision(allowed: true);
  }

  /// Lista os canais bloqueados de um perfil.
  Future<List<String>> getBlockedChannels(String profileId) async {
    try {
      final response = await _dio.get('/parental/channels/blocked/$profileId');
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((e) => (e as Map<String, dynamic>)['channel_id']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// Bloqueia um canal para um perfil.
  Future<bool> blockChannel(String profileId, String channelId) async {
    try {
      final response = await _dio.post(
        '/parental/channels/$profileId/block',
        data: {'channel_id': channelId},
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Desbloqueia um canal para um perfil.
  Future<bool> unblockChannel(String profileId, String channelId) async {
    try {
      final response = await _dio.delete(
        '/parental/channels/$profileId/unblock/$channelId',
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Obtém o tempo de uso diário.
  Future<Map<String, dynamic>?> getUsage(String profileId) async {
    try {
      final response = await _dio.get('/parental/usage/$profileId');
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  /// Registra tempo de uso.
  Future<bool> recordUsage(String profileId, int minutes) async {
    try {
      final response = await _dio.post(
        '/parental/usage/$profileId',
        data: minutes,
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
