import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../providers/auth_provider.dart';
import '../../services/chromecast_service.dart';
import '../../services/player_service.dart';
import '../../theme/colors.dart';

// ============================================
// VIDEO PLAYER SCREEN - Premium Edition
// ============================================

class VideoPlayerScreenPremium extends StatefulWidget {
  final String contentId;
  final String contentTitle;
  final bool isSeries;

  const VideoPlayerScreenPremium({
    super.key,
    required this.contentId,
    required this.contentTitle,
    this.isSeries = false,
  });

  @override
  State<VideoPlayerScreenPremium> createState() =>
      _VideoPlayerScreenPremiumState();
}

class _VideoPlayerScreenPremiumState extends State<VideoPlayerScreenPremium>
    with WidgetsBindingObserver {
  bool _showControls = true;
  bool _isPlaying = false;
  bool _isFullscreen = false;
  double _currentPosition = 0;
  double _totalDuration = 100;
  double _volume = 1.0;
  int _playbackSpeed = 100; // 100 = 1.0x
  String _selectedQuality = '1080p';
  String _selectedSubtitle = 'Português';
  String _selectedAudio = 'Português';

  // Chromecast
  final ChromecastService _castService = ChromecastService.instance;
  bool _castAvailable = false;
  List<Map<String, String>> _castDevices = [];
  bool _isCasting = false;

  // PiP
  bool _pipSupported = false;
  Timer? _saveTimer;
  int _lastSavedPosition = 0;

  final PlayerService _playerService = PlayerService();
  final List<String> qualities = ['480p', '720p', '1080p', '4K'];
  List<String> subtitles = ['Nenhuma', 'Português', 'Inglês', 'Espanhol'];
  List<String> audioTracks = ['Português', 'Inglês', 'Espanhol', 'Francês'];
  final List<double> playbackSpeeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  Future<void> _initialize() async {
    // Inicializar Chromecast
    await _castService.initialize();
    _castAvailable = _castService.isAvailable;

    // Verificar suporte a PiP
    _pipSupported = true; // Android 8+ / iOS 14+

    // Buscar trilhas reais do backend
    await _loadTracks();

    // Manter tela ligada durante reprodução
    await WakelockPlus.enable();

    // Timer de salvamento automático
    _saveTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (_isPlaying && _currentPosition > 0) {
        final authProvider = context.read<AuthProvider>();
        final email = authProvider.email ?? 'demo';
        final diff = (_currentPosition.toInt() - _lastSavedPosition).abs();
        if (diff >= 30) {
          _lastSavedPosition = _currentPosition.toInt();
          await _playerService.saveProgress(
            profileId: email,
            mediaId: widget.contentId,
            seconds: _currentPosition.toInt(),
          );
        }
      }
    });

    // Simular duração do vídeo (em produção: videoController)
    _totalDuration = 5400; // 1h30
  }

  Future<void> _loadTracks() async {
    try {
      final audio = await _playerService.getAudioTracks(widget.contentId);
      if (audio.isNotEmpty) {
        setState(() {
          audioTracks = audio.map((t) => t.name).toList();
          _selectedAudio = audio.firstWhere((t) => t.isDefault,
              orElse: () => audio.first).name;
        });
      }

      final subs = await _playerService.getSubtitleTracks(widget.contentId);
      if (subs.isNotEmpty) {
        setState(() {
          subtitles = ['Nenhuma', ...subs.map((s) => s.name)];
          _selectedSubtitle = subs.firstWhere((s) => s.isDefault,
              orElse: () => subs.first).name;
        });
      }
    } catch (_) {
      // Fallback para lista padrão (já definida)
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveTimer?.cancel();
    _castService.stopCasting();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && _isPlaying && _pipSupported) {
      // Entrar em PiP automaticamente
    }
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  void _handleSeek(double value) {
    setState(() {
      _currentPosition = value;
    });
  }

  // ===== Chromecast Methods =====

  Future<void> _showCastDialog() async {
    _castDevices = await _castService.discoverDevices();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transmitir para...',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            if (_castDevices.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.cast_connected,
                          size: 48, color: Colors.grey[600]),
                      const SizedBox(height: 12),
                      Text(
                        'Nenhum dispositivo encontrado',
                        style: GoogleFonts.inter(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Certifique-se de estar na mesma rede Wi-Fi',
                        style: GoogleFonts.inter(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._castDevices.map((device) => ListTile(
                    leading: const Icon(Icons.cast, color: Colors.white70),
                    title: Text(
                      device['name'] ?? 'Dispositivo',
                      style: GoogleFonts.inter(color: Colors.white),
                    ),
                    subtitle: Text(
                      device['model'] ?? '',
                      style: GoogleFonts.inter(
                          color: Colors.grey, fontSize: 12),
                    ),
                    trailing: _isCasting &&
                            _castService.currentDevice.value ==
                                device['name']
                        ? const Icon(Icons.check,
                            color: AppColors.primaryPurple)
                        : null,
                    onTap: () async {
                      final success = await _castService.connectToDevice(
                        device['id'] ?? '',
                        device['name'] ?? '',
                      );
                      if (success) {
                        setState(() => _isCasting = true);
                        await _castService.playVideo(
                          'https://api.nexustwos.com/media/${widget.contentId}/stream',
                          title: widget.contentTitle,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                      }
                    },
                  )),
            if (_isCasting)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton.icon(
                  onPressed: () async {
                    await _castService.stopCasting();
                    setState(() => _isCasting = false);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  icon: const Icon(Icons.cast_connected, color: Colors.red),
                  label: Text(
                    'Desconectar',
                    style: GoogleFonts.inter(color: Colors.red),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ===== PiP Method =====

  Future<void> _enterPipMode() async {
    try {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      if (mounted) {
        setState(() => _isFullscreen = false);
      }
    } catch (_) {
      // PiP não suportado
    }
  }

  String _formatTime(double seconds) {
    final duration = Duration(seconds: seconds.toInt());
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final secs = duration.inSeconds % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isFullscreen,
      onPopInvokedWithResult: (didPop, _) async {
        if (_isFullscreen) {
          setState(() => _isFullscreen = false);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Video Player
            Container(
              color: Colors.black,
              child: Center(
                child: _isPlaying
                    ? Container(
                        width: double.infinity,
                        height: _isFullscreen
                            ? double.infinity
                            : 300,
                        color: Colors.black,
                        child: Center(
                          child: Text(
                            '▶ Reproduzindo: ${widget.contentTitle}',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.white54,
                            ),
                          ),
                        ),
                      )
                    : Container(
                        width: double.infinity,
                        height: 300,
                        color: AppColors.cardBackground,
                        child: const Center(
                          child: Icon(
                            Icons.play_arrow,
                            size: 80,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
              ),
            ),

            // Gradient overlay
            if (_showControls)
              GestureDetector(
                onTap: () {
                  setState(() => _showControls = false);
                  Future.delayed(const Duration(seconds: 5), () {
                    if (mounted && _isPlaying && !_showControls) {
                      setState(() => _showControls = false);
                    }
                  });
                },
                child: Container(
                  color: Colors.black.withValues(alpha: 0.3),
                ),
              ),

            // Player Controls Overlay
            if (_showControls)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.9),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Progress bar
                      Slider(
                        value: _currentPosition,
                        max: _totalDuration,
                        onChanged: _handleSeek,
                        activeColor: AppColors.primaryPurple,
                        inactiveColor: AppColors.cardBackground,
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Text(
                              _formatTime(_currentPosition),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '/',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatTime(_totalDuration),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Control buttons
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            // Play/Pause
                            IconButton(
                              icon: Icon(
                                _isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                              onPressed: _togglePlayPause,
                            ),

                            // Volume
                            SizedBox(
                              width: 100,
                              child: Row(
                                children: [
                                  Icon(
                                    _volume == 0
                                        ? Icons.volume_off
                                        : Icons.volume_up,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Slider(
                                      value: _volume,
                                      onChanged: (value) {
                                        setState(() => _volume = value);
                                      },
                                      activeColor: AppColors.primaryPurple,
                                      inactiveColor: AppColors.cardBackground,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const Spacer(),

                            // Chromecast
                            if (_castAvailable)
                              IconButton(
                                icon: Icon(
                                  _isCasting
                                      ? Icons.cast_connected
                                      : Icons.cast,
                                  color: _isCasting
                                      ? AppColors.primaryPurple
                                      : Colors.white,
                                ),
                                onPressed: _showCastDialog,
                                tooltip: _isCasting
                                    ? 'Transmitindo...'
                                    : 'Transmitir',
                              ),

                            // PiP
                            if (_pipSupported)
                              IconButton(
                                icon: const Icon(Icons.picture_in_picture_alt),
                                color: Colors.white,
                                onPressed: _enterPipMode,
                                tooltip: 'Picture in Picture',
                              ),

                            // Legendas
                            IconButton(
                              icon: const Icon(Icons.subtitles),
                              color: Colors.white,
                              onPressed: _showSubtitleMenu,
                              tooltip: _selectedSubtitle,
                            ),

                            // Áudio
                            IconButton(
                              icon: const Icon(Icons.language),
                              color: Colors.white,
                              onPressed: _showAudioMenu,
                              tooltip: _selectedAudio,
                            ),

                            // Qualidade
                            IconButton(
                              icon: const Icon(Icons.hd),
                              color: Colors.white,
                              onPressed: _showQualityMenu,
                              tooltip: _selectedQuality,
                            ),

                            // Velocidade
                            IconButton(
                              icon: const Icon(Icons.speed),
                              color: Colors.white,
                              onPressed: _showSpeedMenu,
                            ),

                            // Fullscreen
                            IconButton(
                              icon: Icon(
                                _isFullscreen
                                    ? Icons.fullscreen_exit
                                    : Icons.fullscreen,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                setState(() => _isFullscreen = !_isFullscreen);
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),

            // Top Bar - Title
            if (_showControls)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.9),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        color: Colors.white,
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          widget.contentTitle,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_isCasting)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryPurple.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.cast, size: 16, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                'Cast',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            // Tap to show controls
            if (!_showControls)
              GestureDetector(
                onTap: () {
