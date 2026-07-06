import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/profile.dart';
import '../utils/constants.dart';

class ProfileService {
  Future<List<Profile>> getProfiles(String token) async {
    final response = await http.get(
      Uri.parse('$apiUrl/profiles'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final data = jsonDecode(response.body);
    if (data is List) {
      return data.map<Profile>((e) => Profile.fromJson(e)).toList();
    }

    return [];
  }
}
