import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

class _VideoPlayerScreenPremiumState extends State<VideoPlayerScreenPremium> {
  bool _showControls = true;
  bool _isPlaying = false;
  bool _isFullscreen = false;
  double _currentPosition = 0;
final double _totalDuration = 100;
  double _volume = 1.0;
  int _playbackSpeed = 100; // 100 = 1.0x
  String _selectedQuality = '1080p';
  String _selectedSubtitle = 'Português';
  String _selectedAudio = 'Português';

  final List<String> qualities = ['480p', '720p', '1080p', '4K'];
  final List<String> subtitles = [
    'Nenhuma',
    'Português',
    'Inglês',
    'Espanhol'
  ];
  final List<String> audioTracks = [
    'Português',
    'Inglês',
    'Espanhol',
    'Francês'
  ];
  final List<double> playbackSpeeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() {
    // TODO: Inicializar video_player com URL real
    // _videoController = VideoPlayerController.network(videoUrl)
    //   ..initialize().then((_) {
    //     setState(() {
    //       _totalDuration = _videoController.value.duration.inSeconds.toDouble();
    //     });
    //   });
  }

  @override
  void dispose() {
    // _videoController.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      // if (_isPlaying) {
      //   _videoController.play();
      // } else {
      //   _videoController.pause();
      // }
    });
  }

  void _handleSeek(double value) {
    setState(() {
      _currentPosition = value;
      // _videoController.seekTo(Duration(seconds: value.toInt()));
    });
  }

  void _showQualityMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildQualityMenu(),
    );
  }

  void _showSubtitleMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildSubtitleMenu(),
    );
  }

  void _showAudioMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildAudioMenu(),
    );
  }

  void _showSpeedMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildSpeedMenu(),
    );
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
                child: Container(
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

            // Controles do player
            if (_showControls)
              GestureDetector(
                onTap: () {
                  setState(() => _showControls = false);
                  Future.delayed(const Duration(seconds: 5), () {
                    if (mounted && _isPlaying) {
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
                            // Tempo atual
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
                            // Tempo total
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

                      // Botões de controle
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

                            // Legenda
                            IconButton(
                              icon: const Icon(Icons.subtitles),
                              color: Colors.white,
                              onPressed: _showSubtitleMenu,
                            ),

                            // Áudio
                            IconButton(
                              icon: const Icon(Icons.language),
                              color: Colors.white,
                              onPressed: _showAudioMenu,
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

            // Top Bar - Título
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
                    ],
                  ),
                ),
              ),

            // Clique para mostrar controles
            if (!_showControls)
              GestureDetector(
                onTap: () {
                  setState(() => _showControls = true);
                },
                child: Container(
                  color: Colors.transparent,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQualityMenu() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Qualidade',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          ...qualities.map(
            (quality) => ListTile(
              title: Text(
                quality,
                style: GoogleFonts.inter(color: Colors.white),
              ),
              trailing: _selectedQuality == quality
                  ? const Icon(Icons.check, color: AppColors.primaryPurple)
                  : null,
              onTap: () {
                setState(() => _selectedQuality = quality);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitleMenu() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Legendas',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          ...subtitles.map(
            (subtitle) => ListTile(
              title: Text(
                subtitle,
                style: GoogleFonts.inter(color: Colors.white),
              ),
              trailing: _selectedSubtitle == subtitle
                  ? const Icon(Icons.check, color: AppColors.primaryPurple)
                  : null,
              onTap: () {
                setState(() => _selectedSubtitle = subtitle);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioMenu() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Áudio',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          ...audioTracks.map(
            (audio) => ListTile(
              title: Text(
                audio,
                style: GoogleFonts.inter(color: Colors.white),
              ),
              trailing: _selectedAudio == audio
                  ? const Icon(Icons.check, color: AppColors.primaryPurple)
                  : null,
              onTap: () {
                setState(() => _selectedAudio = audio);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedMenu() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Velocidade',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          ...playbackSpeeds.map(
            (speed) {
              final speedLabel =
                  speed == 1.0 ? 'Normal' : '${speed.toStringAsFixed(2)}x';
              final isSelected = _playbackSpeed == (speed * 100).toInt();
              return ListTile(
                title: Text(
                  speedLabel,
                  style: GoogleFonts.inter(color: Colors.white),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check, color: AppColors.primaryPurple)
                    : null,
                onTap: () {
                  setState(() => _playbackSpeed = (speed * 100).toInt());
                  Navigator.pop(context);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
