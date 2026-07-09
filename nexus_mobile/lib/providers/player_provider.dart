import 'package:flutter/material.dart';

class PlayerProvider extends ChangeNotifier {
  bool playing = false;
  bool fullscreen = false;
  double volume = 1.0;

  void toggle() {
    playing = !playing;
    notifyListeners();
  }

  void setVolume(double v) {
    volume = v;
    notifyListeners();
  }

  void setFullscreen(bool value) {
    fullscreen = value;
    notifyListeners();
  }
}
