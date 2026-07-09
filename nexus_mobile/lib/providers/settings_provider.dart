import 'package:flutter/material.dart';

class SettingsProvider extends ChangeNotifier {
  bool darkMode = true;
  String language = 'pt-BR';
  bool notifications = true;

  void changeTheme(bool value) {
    darkMode = value;
    notifyListeners();
  }

  void changeLanguage(String value) {
    language = value;
    notifyListeners();
  }

  void toggleNotifications(bool value) {
    notifications = value;
    notifyListeners();
  }
}
