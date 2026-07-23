import 'dart:convert';

import 'package:dio/dio.dart';

import '../models/media.dart';
import '../utils/constants.dart';

class MediaService {
  final Dio _dio;

  MediaService({String? token})
      : _dio = Dio(BaseOptions(
          baseUrl: apiUrl,
          connectTimeout: apiTimeout,
          receiveTimeout: apiTimeout,
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ));

  /// Define ou atualiza o token de autenticação
  void setToken(String? token) {
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    } else {
      _dio.options.headers.remove('Authorization');
    }
  }

  Future<List<Media>> getCatalog() async {
    try {
      final response = await _dio.get('/media');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return data.map<Media>((e) => Media.fromJson(e)).toList();
        }
      }
    } on DioException {
      // Log error silencioso
    } catch (_) {}
    return [];
  }

  Future<List<Media>> getMovies() async {
    try {
      final response = await _dio.get('/media/movies');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return data.map<Media>((e) => Media.fromJson(e)).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  Future<List<Media>> getSeries() async {
    try {
      final response = await _dio.get('/media/series');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return data.map<Media>((e) => Media.fromJson(e)).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  Future<Media?> getDetails(String id) async {
    try {
      final response = await _dio.get('/media/$id');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return Media.fromJson(data);
        }
      }
    } catch (_) {}
    return null;
  }
}
