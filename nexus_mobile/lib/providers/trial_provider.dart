import 'package:flutter/material.dart';
import '../services/trial_service.dart';

class TrialProvider with ChangeNotifier {
  final TrialService _trialService = TrialService();

  bool _isLoading = false;
  bool _isTrialActive = false;
  int _daysRemaining = 0;
  DateTime? _trialEndsAt;
  String _planType = 'Free';
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get isTrialActive => _isTrialActive;
  int get daysRemaining => _daysRemaining;
  DateTime? get trialEndsAt => _trialEndsAt;
  String get planType => _planType;
  String? get errorMessage => _errorMessage;

  Future<void> loadTrialStatus(String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final status = await _trialService.getTrialStatus(token);
      _isTrialActive = status['is_trial'] as bool;
      _daysRemaining = status['days_remaining'] as int;
      _trialEndsAt = status['trial_ends_at'] != null
          ? DateTime.parse(status['trial_ends_at'].toString())
          : null;
      _planType = status['plan_type'] as String;
    } catch (e) {
      _errorMessage = 'Erro ao carregar status do trial: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> checkTrialExpiration(String token) async {
    try {
      final result = await _trialService.checkTrialExpiration(token);
      if (result['status'] == 'expired') {
        _isTrialActive = false;
        _planType = 'Free';
        _daysRemaining = 0;
        notifyListeners();
        return true; // Trial expirou
      }
      return false; // Trial ainda ativo
    } catch (e) {
      _errorMessage = 'Erro ao verificar expiração: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> upgradeToPlan(String token, String plan) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _trialService.upgradeToPlan(token, plan);
      _isTrialActive = false;
      _planType = 'Premium';
      _daysRemaining = 0;
      _trialEndsAt = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao fazer upgrade: $e';
      notifyListeners();
      return false;
    }
  }

  void reset() {
    _isTrialActive = false;
    _daysRemaining = 0;
    _trialEndsAt = null;
    _planType = 'Free';
    _errorMessage = null;
    _isLoading = false;
  }
}
