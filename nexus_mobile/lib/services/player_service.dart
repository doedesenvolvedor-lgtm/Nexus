import 'dart:convert';

import 'package:http/http.dart' as http;

import '../utils/constants.dart';

class PlayerService {
  Future<void> saveProgress({
    required String profileId,
    required String mediaId,
    required int seconds,
  }) async {
    try {
      await http.post(
        Uri.parse('$apiUrl/history'),
        headers: {'Content-Type': 'application/json'},
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

  Future<int> getSavedPosition(String mediaId, String profileId) async {
    try {
      final response = await http
          .get(Uri.parse('$apiUrl/history/$mediaId?profile_id=$profileId'))
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
}
