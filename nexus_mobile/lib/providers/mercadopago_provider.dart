import 'package:flutter/material.dart';
import '../services/mercadopago_service.dart';

class MercadoPagoProvider extends ChangeNotifier {
  String? _paymentUrl;
  bool _isLoading = false;
  String? _error;
  bool _paymentProcessing = false;

  String? get paymentUrl => _paymentUrl;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get paymentProcessing => _paymentProcessing;

  Future<String?> createCheckout({
    required String token,
    required String plan,
    required double price,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final paymentUrl = await MercadoPagoService.createCheckout(
        token: token,
        plan: plan,
        price: price,
      );

      _paymentUrl = paymentUrl;
      notifyListeners();

      return paymentUrl;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> openPayment() async {
    if (_paymentUrl == null) {
      _error = 'URL de pagamento não disponível';
      notifyListeners();
      return false;
    }

    try {
      _paymentProcessing = true;
      notifyListeners();

      return await MercadoPagoService.openPaymentUrl(_paymentUrl!);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _paymentProcessing = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> getPaymentHistory({
    required String token,
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final history = await MercadoPagoService.getPaymentHistory(
        token: token,
        limit: limit,
        offset: offset,
      );

      _isLoading = false;
      notifyListeners();
      return history;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  void reset() {
    _paymentUrl = null;
    _isLoading = false;
    _error = null;
    _paymentProcessing = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
