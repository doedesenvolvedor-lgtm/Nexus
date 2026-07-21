import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class TrialService {
  static const Duration _timeout = Duration(seconds: 30);

  Future<Map<String, dynamic>> getTrialStatus(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/subscriptions/me/trial-status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erro ao obter status do trial: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      throw Exception('Erro de conexão: Não foi possível conectar ao servidor. $e');
    } on TimeoutException catch (_) {
      throw Exception('Timeout: A solicitação demorou muito tempo');
    } on FormatException catch (e) {
      throw Exception('Erro ao processar resposta: $e');
    } catch (e) {
      throw Exception('Erro ao obter status do trial: $e');
    }
  }

  Future<Map<String, dynamic>> getSubscription(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/subscriptions/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erro ao obter subscription: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      throw Exception('Erro de conexão: $e');
    } on TimeoutException catch (_) {
      throw Exception('Timeout ao obter subscription');
    } catch (e) {
      throw Exception('Erro ao obter subscription: $e');
    }
  }

  Future<Map<String, dynamic>> getUserProfile(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/auth/me/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erro ao obter perfil: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      throw Exception('Erro de conexão ao obter perfil: $e');
    } on TimeoutException catch (_) {
      throw Exception('Timeout ao obter perfil');
    } catch (e) {
      throw Exception('Erro ao obter perfil: $e');
    }
  }

  Future<Map<String, dynamic>> checkTrialExpiration(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/subscriptions/check-trial-expiration'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erro ao verificar expiração: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      throw Exception('Erro de conexão ao verificar expiração: $e');
    } on TimeoutException catch (_) {
      throw Exception('Timeout ao verificar expiração');
    } catch (e) {
      throw Exception('Erro ao verificar expiração: $e');
    }
  }

  Future<Map<String, dynamic>> upgradeToPlan(
    String token,
    String plan,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/subscriptions/upgrade-trial'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'plan': plan}),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erro ao fazer upgrade: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      throw Exception('Erro de conexão ao fazer upgrade: $e');
    } on TimeoutException catch (_) {
      throw Exception('Timeout ao fazer upgrade');
    } catch (e) {
      throw Exception('Erro ao fazer upgrade: $e');
    }
  }
}
