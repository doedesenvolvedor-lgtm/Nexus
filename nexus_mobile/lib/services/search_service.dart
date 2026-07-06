import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/media.dart';
import '../utils/constants.dart';

class SearchService {
  Future<List<Media>> search(String text) async {
    final response = await http.get(Uri.parse('$apiUrl/media/search?q=$text'));

    if (response.statusCode != 200) {
      return [];
    }

    final data = jsonDecode(response.body);
    if (data is List) {
      return data.map<Media>((e) => Media.fromJson(e)).toList();
    }

    return [];
  }

  Future<List<Media>> recommendations(String emotion) async {
    final response = await http.get(Uri.parse('$apiUrl/media/ai-search?emotion=$emotion'));

    if (response.statusCode != 200) {
      return [];
    }

    final data = jsonDecode(response.body);
    if (data is List) {
      return data.map<Media>((e) => Media.fromJson(e)).toList();
    }

    return [];
  }
}
