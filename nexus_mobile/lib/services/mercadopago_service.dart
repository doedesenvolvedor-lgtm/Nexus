import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import '../utils/constants.dart';

class MercadoPagoService {
  static const Duration _timeout = Duration(seconds: 30);

  static Future<String> createCheckout({
    required String token,
    required String plan,
    required double price,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/payments/checkout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'plan': plan,
          'price': price,
        }),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['payment_url'] as String;
      } else {
        throw Exception('Erro ao criar checkout: ${response.statusCode} - ${response.body}');
      }
    } on SocketException catch (e) {
      throw Exception('Erro de conexão ao criar checkout: Verifique sua conexão de internet. $e');
    } on TimeoutException catch (_) {
      throw Exception('Timeout: O servidor demorou muito para responder. Tente novamente.');
    } on FormatException catch (e) {
      throw Exception('Erro ao processar resposta do servidor: $e');
    } catch (e) {
      throw Exception('Erro ao criar checkout: $e');
    }
  }

  static Future<bool> openPaymentUrl(String paymentUrl) async {
    try {
      if (await canLaunchUrl(Uri.parse(paymentUrl))) {
        await launchUrl(
          Uri.parse(paymentUrl),
          mode: LaunchMode.externalApplication,
        );
        return true;
      } else {
        throw Exception('Não foi possível abrir URL de pagamento');
      }
    } catch (e) {
      throw Exception('Erro ao abrir pagamento: $e');
    }
  }

  static Future<Map<String, dynamic>> getPaymentHistory({
    required String token,
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/payments/me/history?limit=$limit&offset=$offset'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erro ao buscar histórico: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      throw Exception('Erro de conexão ao buscar histórico: $e');
    } on TimeoutException catch (_) {
      throw Exception('Timeout ao buscar histórico de pagamentos');
    } catch (e) {
      throw Exception('Erro ao buscar histórico: $e');
    }
  }
}
