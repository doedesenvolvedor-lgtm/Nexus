import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class TrialService {
  Future<Map<String, dynamic>> getTrialStatus(String token) async {
    final response = await http.get(
      Uri.parse('$apiUrl/subscriptions/me/trial-status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro ao obter status do trial: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getSubscription(String token) async {
    final response = await http.get(
      Uri.parse('$apiUrl/subscriptions/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro ao obter subscription: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getUserProfile(String token) async {
    final response = await http.get(
      Uri.parse('$apiUrl/auth/me/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro ao obter perfil: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> checkTrialExpiration(String token) async {
    final response = await http.post(
      Uri.parse('$apiUrl/subscriptions/check-trial-expiration'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro ao verificar expiração: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> upgradeToPlan(
    String token,
    String plan,
  ) async {
    final response = await http.post(
      Uri.parse('$apiUrl/subscriptions/upgrade-trial'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'plan': plan}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro ao fazer upgrade: ${response.statusCode}');
    }
  }
}
