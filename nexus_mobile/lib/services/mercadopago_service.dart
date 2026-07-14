import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class MercadoPagoService {
  static const String apiUrl = 'http://10.0.2.2:8000'; // Android emulator
  // Para iOS: 'http://localhost:8000'

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
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['payment_url'] as String;
      } else {
        throw Exception('Erro ao criar checkout: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro: $e');
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
        throw Exception('Não foi possível abrir URL');
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
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erro ao buscar histórico');
      }
    } catch (e) {
      throw Exception('Erro: $e');
    }
  }
}
