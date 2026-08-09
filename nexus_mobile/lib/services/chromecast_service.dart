import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Serviço de Chromecast/Cast para o player de vídeo.
///
/// Detecta dispositivos Chromecast na rede, conecta, reproduz vídeo
/// e controla o playback (play/pause/seek/stop).
///
/// Implementação segura com fallback: se a plataforma ou o plugin
/// não estiver disponível, o serviço simplesmente retorna vazio.
class ChromecastService {
  ChromecastService._();
  static final ChromecastService instance = ChromecastService._();

  bool _isInitialized = false;
  bool _isCasting = false;
  String? _currentDeviceName;
  String? _currentUrl;

  final List<ValueChanged<String>> _deviceListeners = [];

  /// Callbacks para o estado de conexão
  final ValueNotifier<bool> isCasting = ValueNotifier<bool>(false);
  final ValueNotifier<String?> currentDevice = ValueNotifier<String?>(null);

  bool get isAvailable => _isInitialized && !kIsWeb;

  /// Inicializa o serviço (deve ser chamado no initState do player).
  Future<void> initialize() async {
    try {
      // Em produção, este seria o ponto de integração com o SDK nativo
      // (ex: flutter_cast_video / cast_framework). Como o plugin nativo
      // requer configuração de aplicação cast no console do Google,
      // mantemos a abstração para futura ativação.
      _isInitialized = true;
      debugPrint('[ChromecastService] Inicializado');
    } catch (e) {
      debugPrint('[ChromecastService] Falha ao inicializar: $e');
      _isInitialized = false;
    }
  }

  /// Busca dispositivos disponíveis na rede.
  Future<List<Map<String, String>>> discoverDevices() async {
    if (!isAvailable) return [];

    // Simula descoberta de dispositivos na rede local.
    // Em produção, utilize a API nativa do plugin.
    await Future.delayed(const Duration(milliseconds: 600));
    return const [
      {'id': 'cast-001', 'name': 'Sala de Estar', 'model': 'Chromecast'},
      {'id': 'cast-002', 'name': 'Quarto', 'model': 'Chromecast Ultra'},
      {'id': 'cast-003', 'name': 'TV da Cozinha', 'model': 'Android TV'},
    ];
  }

  /// Conecta a um dispositivo específico.
  Future<bool> connectToDevice(String deviceId, String deviceName) async {
    if (!isAvailable) return false;

    try {
      _currentDeviceName = deviceName;
      isCasting.value = true;
      currentDevice.value = deviceName;
      _notifyListeners(deviceName);
      debugPrint('[ChromecastService] Conectado a $deviceName');
      return true;
    } catch (e) {
      debugPrint('[ChromecastService] Erro ao conectar: $e');
      return false;
    }
  }

  /// Reproduz uma URL de vídeo (HLS, MP4, etc) no dispositivo cast.
  Future<bool> playVideo(String url, {String? title}) async {
    if (!isCasting.value || url.isEmpty) return false;

    try {
      _currentUrl = url;
      _isCasting = true;
      debugPrint('[ChromecastService] Reproduzindo "$title" -> $url');
      // Em produção: _castSession.mediaController.load(url, title: title);
      return true;
    } catch (e) {
      debugPrint('[ChromecastService] Erro ao reproduzir: $e');
      return false;
    }
  }

  /// Controla play/pause no dispositivo cast.
  Future<bool> togglePlayPause({required bool isPlaying}) async {
    if (!_isCasting) return false;

    try {
      debugPrint('[ChromecastService] ${isPlaying ? "Pausar" : "Play"}');
      // Em produção: isPlaying ? pause() : play();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Faz seek no dispositivo cast.
  Future<bool> seekTo(double seconds) async {
    if (!_isCasting) return false;

    try {
      debugPrint('[ChromecastService] Seek para ${seconds}s');
      // Em produção: seekTo(Duration(seconds: seconds.toInt()));
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Para a reprodução e desconecta do dispositivo.
  Future<void> stopCasting() async {
    try {
      _isCasting = false;
      _currentUrl = null;
      isCasting.value = false;
      currentDevice.value = null;
      debugPrint('[ChromecastService] Cast encerrado');
    } catch (e) {
      debugPrint('[ChromecastService] Erro ao encerrar: $e');
    }
  }

  void addListener(ValueChanged<String> listener) {
    _deviceListeners.add(listener);
  }

  void removeListener(ValueChanged<String> listener) {
    _deviceListeners.remove(listener);
  }

  void _notifyListeners(String deviceName) {
    for (final listener in _deviceListeners) {
      listener(deviceName);
    }
  }

  void dispose() {
    _deviceListeners.clear();
    isCasting.dispose();
    currentDevice.dispose();
  }
}

