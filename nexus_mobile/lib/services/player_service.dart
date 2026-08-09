import 'dart:convert';
import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../utils/constants.dart';

/// Estrutura de uma trilha de áudio extraída de HLS.
class AudioTrack {
  final String name;
  final String language;
  final String groupId;
  final bool isDefault;

  AudioTrack({
    required this.name,
    required this.language,
    required this.groupId,
    this.isDefault = false,
  });

  factory AudioTrack.fromJson(Map<String, dynamic> json) {
    return AudioTrack(
      name: json['name'] as String? ?? 'Desconhecido',
      language: json['language'] as String? ?? 'und',
      groupId: json['group_id'] as String? ?? '',
      isDefault: json['default'] as bool? ?? false,
    );
  }
}

/// Estrutura de uma faixa de legenda extraída de HLS.
class SubtitleTrack {
  final String name;
  final String language;
  final String uri;
  final bool isDefault;

  SubtitleTrack({
    required this.name,
    required this.language,
    required this.uri,
    this.isDefault = false,
  });

  factory SubtitleTrack.fromJson(Map<String, dynamic> json) {
    return SubtitleTrack(
      name: json['name'] as String? ?? 'Desconhecido',
      language: json['language'] as String? ?? 'und',
      uri: json['uri'] as String? ?? '',
      isDefault: json['default'] as bool? ?? false,
    );
  }
}

/// Estrutura de uma resolução de vídeo do HLS.
class VideoQuality {
  final String label;
  final int bandwidth;
  final String resolution;
  final String playlistUrl;

  VideoQuality({
    required this.label,
    required this.bandwidth,
    required this.resolution,
    required this.playlistUrl,
  });

  factory VideoQuality.fromJson(Map<String, dynamic> json) {
    return VideoQuality(
      label: json['label'] as String? ?? 'Auto',
      bandwidth: json['bandwidth'] as int? ?? 0,
      resolution: json['resolution'] as String? ?? 'auto',
      playlistUrl: json['playlist_url'] as String? ?? '',
    );
  }
}

/// Serviço de player com suporte a HLS, salvamento de progresso,
/// parsing de trilhas de áudio/legenda e qualidades.
class PlayerService {
  String? _token;

  /// Define o token de autenticação usado nas chamadas autenticadas.
  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> _authHeaders() => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  /// Salva o progresso de reprodução no servidor.
  Future<void> saveProgress({
    required String profileId,
    required String mediaId,
    required int seconds,
  }) async {
    try {
      await http.post(
        Uri.parse('$apiUrl/history'),
        headers: _authHeaders(),
        body: jsonEncode({
          'profile_id': profileId,
          'media_id': mediaId,
          'last_position_seconds': seconds,
        }),
      ).timeout(apiTimeout);
    } catch (_) {
      // Falha silenciosa - não bloquear o usuário por erro de save
    }
  }

  /// Obtém a posição salva de um conteúdo.
  Future<int> getSavedPosition(String mediaId, String profileId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$apiUrl/history/$mediaId?profile_id=$profileId'),
            headers: _authHeaders(),
          )
          .timeout(apiTimeout);
      if (response.statusCode != 200) {
        return 0;
      }

      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        return (data['last_position_seconds'] ?? 0) as int;
      }
    } catch (_) {
      // Falha silenciosa
    }

    return 0;
  }

  /// Obtém as trilhas de áudio disponíveis de um conteúdo HLS.
  ///
  /// Faz uma requisição ao backend que retorna as faixas de áudio
  /// extraídas do master playlist HLS.
  Future<List<AudioTrack>> getAudioTracks(String mediaId) async {
    try {
      final response = await http
          .get(Uri.parse('$apiUrl/media/$mediaId/audio-tracks'))
          .timeout(apiTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        return data
            .map((e) => AudioTrack.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      debugPrint('[PlayerService] Erro ao buscar trilhas de áudio');
    }

    // Fallback com trilhas padrão
    return [
      AudioTrack(name: 'Português', language: 'pt', groupId: 'audio-pt', isDefault: true),
      AudioTrack(name: 'English', language: 'en', groupId: 'audio-en'),
      AudioTrack(name: 'Español', language: 'es', groupId: 'audio-es'),
    ];
  }

  /// Obtém as legendas disponíveis de um conteúdo HLS.
  Future<List<SubtitleTrack>> getSubtitleTracks(String mediaId) async {
    try {
      final response = await http
          .get(Uri.parse('$apiUrl/media/$mediaId/subtitles'))
          .timeout(apiTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        return data
            .map((e) => SubtitleTrack.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      debugPrint('[PlayerService] Erro ao buscar legendas');
    }

    // Fallback com legendas padrão
    return [
      SubtitleTrack(name: 'Português', language: 'pt', uri: '', isDefault: true),
      SubtitleTrack(name: 'English', language: 'en', uri: ''),
      SubtitleTrack(name: 'Nenhuma', language: 'off', uri: ''),
    ];
  }

  /// Obtém as qualidades de vídeo disponíveis.
  Future<List<VideoQuality>> getVideoQualities(String mediaId) async {
    try {
      final response = await http
          .get(Uri.parse('$apiUrl/media/$mediaId/qualities'))
          .timeout(apiTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        return data
            .map((e) => VideoQuality.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      debugPrint('[PlayerService] Erro ao buscar qualidades');
    }

    // Fallback com qualidades padrão
    return [
      VideoQuality(label: '4K', bandwidth: 25000000, resolution: '3840x2160', playlistUrl: ''),
      VideoQuality(label: '1080p', bandwidth: 5000000, resolution: '1920x1080', playlistUrl: ''),
      VideoQuality(label: '720p', bandwidth: 2800000, resolution: '1280x720', playlistUrl: ''),
      VideoQuality(label: '480p', bandwidth: 1200000, resolution: '854x480', playlistUrl: ''),
    ];
  }

  /// Obtém a URL de streaming com token JWT temporário.
  Future<String?> getStreamUrl(String mediaId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/media/$mediaId/play'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(apiTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['stream'] as String?;
      }
    } catch (_) {
      debugPrint('[PlayerService] Erro ao obter URL de streaming');
    }
    return null;
  }
}
