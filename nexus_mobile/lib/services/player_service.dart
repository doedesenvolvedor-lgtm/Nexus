import 'dart:convert';

import 'package:http/http.dart' as http;

import '../utils/constants.dart';

class PlayerService {
  Future<void> saveProgress({
    required String profileId,
    required String mediaId,
    required int seconds,
  }) async {
    await http.post(
      Uri.parse('$apiUrl/history'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'profile_id': profileId,
        'media_id': mediaId,
        'last_position_seconds': seconds,
      }),
    );
  }

  Future<int> getSavedPosition(String mediaId) async {
    final response = await http.get(Uri.parse('$apiUrl/history/$mediaId'));
    if (response.statusCode != 200) {
      return 0;
    }

    final data = jsonDecode(response.body);
    if (data is Map<String, dynamic>) {
      return (data['last_position_seconds'] ?? 0) as int;
    }

    return 0;
  }
}
