import 'dart:async';

import 'package:flutter/material.dart';

import '../services/parental_control_service.dart';

/// Provider de Controle Parental.
///
/// Gerencia o estado do PIN, configurações, sessão de desbloqueio e tempo de uso.
class ParentalControlProvider extends ChangeNotifier {
  final ParentalControlService _service;

  ParentalControlProvider({String? token})
      : _service = ParentalControlService(token: token);

  ParentalSettings? _settings;
  bool _loading = false;
  bool _unlocked = false;
  DateTime? _lastUnlockTime;
  Timer? _inactivityTimer;
  int _usageMinutes = 0;

  ParentalSettings? get settings => _settings;
  bool get loading => _loading;
  bool get unlocked => _unlocked;
  int get usageMinutes => _usageMinutes;

  /// Define o token de autenticação no serviço.
  void setToken(String? token) => _service.setToken(token);

  /// Indica se o perfil está dentro do bloqueio de inatividade.
  bool get isLocked {
    if (!_unlocked) return true;
    final settings = _settings;
    if (settings == null) return false;
    if (settings.requireAuthAfterMinutes <= 0) return false;
    if (_lastUnlockTime == null) return true;

    final elapsed = DateTime.now().difference(_lastUnlockTime!);
    return elapsed.inMinutes >= settings.requireAuthAfterMinutes;
  }

  /// Carrega as configurações de um perfil.
  Future<ParentalSettings?> loadSettings(String profileId) async {
    _loading = true;
    notifyListeners();
    _settings = await _service.getSettings(profileId);
    _loading = false;
    notifyListeners();
    return _settings;
  }

  /// Atualiza as configurações.
  Future<bool> updateSettings(
    String profileId,
    ParentalSettings settings,
  ) async {
    final ok = await _service.updateSettings(profileId, settings);
    if (ok) {
      _settings = settings;
      notifyListeners();
    }
    return ok;
  }

  /// Define o PIN.
  Future<bool> setPin(String profileId, String pin) {
    return _service.setPin(profileId, pin);
  }

  /// Desbloqueia o perfil mediante PIN.
  Future<bool> unlockWithPin(String profileId, String pin) async {
    final ok = await _service.verifyPin(profileId, pin);
    if (ok) {
      _unlocked = true;
      _lastUnlockTime = DateTime.now();
      _startInactivityTimer();
      notifyListeners();
    }
    return ok;
  }

  /// Desbloqueia conteúdo +18 mediante PIN.
  Future<bool> unlockContent(String profileId, String pin) {
    return _service.unlockContent(profileId, pin);
  }

  /// Verifica o acesso a um conteúdo (decisão centralizada no backend).
  Future<AccessDecision> checkAccess({
    required String profileId,
    required String contentType,
    String? targetId,
    String? rating,
    String? title,
  }) {
    return _service.checkAccess(
      profileId: profileId,
      contentType: contentType,
      targetId: targetId,
      rating: rating,
      title: title,
    );
  }

  /// Obtém o tempo de uso diário.
  Future<void> loadUsage(String profileId) async {
    final usage = await _service.getUsage(profileId);
    if (usage != null) {
      _usageMinutes = (usage['usage_minutes'] as num?)?.toInt() ?? 0;
      notifyListeners();
    }
  }

  /// Registra tempo de uso.
  Future<bool> recordUsage(String profileId, int minutes) async {
    final ok = await _service.recordUsage(profileId, minutes);
    if (ok) {
      _usageMinutes += minutes;
      notifyListeners();
    }
    return ok;
  }

  /// Bloqueia um canal.
  Future<bool> blockChannel(String profileId, String channelId) {
    return _service.blockChannel(profileId, channelId);
  }

  /// Desbloqueia um canal.
  Future<bool> unblockChannel(String profileId, String channelId) {
    return _service.unblockChannel(profileId, channelId);
  }

  /// Lista canais bloqueados.
  Future<List<String>> getBlockedChannels(String profileId) {
    return _service.getBlockedChannels(profileId);
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    final minutes = _settings?.requireAuthAfterMinutes ?? 30;
    if (minutes <= 0) return;
    _inactivityTimer = Timer(Duration(minutes: minutes), () {
      _unlocked = false;
      _lastUnlockTime = null;
      notifyListeners();
    });
  }

  /// Bloqueia manualmente (ex.: ao sair da tela).
  void lock() {
    _unlocked = false;
    _lastUnlockTime = null;
    _inactivityTimer?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }
}
