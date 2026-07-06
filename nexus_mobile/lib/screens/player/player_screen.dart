import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../models/media.dart';
import '../../providers/player_provider.dart';
import '../../services/player_service.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late VideoPlayerController controller;
  final service = PlayerService();
  Timer? saveTimer;
  int savedPosition = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final media = ModalRoute.of(context)!.settings.arguments as Media;

    controller = VideoPlayerController.networkUrl(Uri.parse(media.video))
      ..initialize().then((_) async {
        final position = await service.getSavedPosition(media.id);
        savedPosition = position;
        if (mounted) {
          await controller.seekTo(Duration(seconds: savedPosition));
          setState(() {
            _isLoading = false;
          });
        }
      });

    controller.addListener(() {
      if (!mounted || !controller.value.isPlaying) {
        return;
      }

      final seconds = controller.value.position.inSeconds;
      if (seconds % 5 == 0 && seconds != savedPosition) {
        savedPosition = seconds;
        service.saveProgress(
          profileId: 'demo-profile',
          mediaId: media.id,
          seconds: seconds,
        );
      }
    });
  }

  @override
  void dispose() {
    saveTimer?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PlayerProvider(),
      child: Consumer<PlayerProvider>(
        builder: (context, playerProvider, _) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: SafeArea(
              child: Stack(
                children: [
                  Center(
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : AspectRatio(
                            aspectRatio: controller.value.aspectRatio,
                            child: VideoPlayer(controller),
                          ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      color: Colors.black54,
                      child: Column(
                        children: [
                          VideoProgressIndicator(controller, allowScrubbing: true),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  controller.seekTo(controller.value.position - const Duration(seconds: 10));
                                },
                                icon: const Icon(Icons.replay_10, color: Colors.white),
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    if (controller.value.isPlaying) {
                                      controller.pause();
                                      playerProvider.toggle();
                                    } else {
                                      controller.play();
                                      playerProvider.toggle();
                                    }
                                  });
                                },
                                icon: Icon(
                                  controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                                  color: Colors.white,
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  controller.seekTo(controller.value.position + const Duration(seconds: 10));
                                },
                                icon: const Icon(Icons.forward_10, color: Colors.white),
                              ),
                              Expanded(
                                child: Slider(
                                  value: controller.value.volume,
                                  min: 0,
                                  max: 1,
                                  onChanged: (value) {
                                    controller.setVolume(value);
                                    playerProvider.setVolume(value);
                                  },
                                ),
                              ),
                              IconButton(
                                onPressed: () async {
                                  await controller.setVolume(0);
                                  playerProvider.setVolume(0);
                                },
                                icon: const Icon(Icons.volume_up, color: Colors.white),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
