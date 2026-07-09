import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/media.dart';
import '../utils/constants.dart';

class MediaService {
  Future<List<Media>> getCatalog() async {
    final response = await http.get(Uri.parse('$apiUrl/media'));

    final data = jsonDecode(response.body);
    if (data is List) {
      return data.map<Media>((e) => Media.fromJson(e)).toList();
    }

    return [];
  }

  Future<List<Media>> getMovies() async {
    final response = await http.get(Uri.parse('$apiUrl/media/movies'));

    final data = jsonDecode(response.body);
    if (data is List) {
      return data.map<Media>((e) => Media.fromJson(e)).toList();
    }

    return [];
  }

  Future<List<Media>> getSeries() async {
    final response = await http.get(Uri.parse('$apiUrl/media/series'));

    final data = jsonDecode(response.body);
    if (data is List) {
      return data.map<Media>((e) => Media.fromJson(e)).toList();
    }

    return [];
  }
}
