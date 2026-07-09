import 'package:flutter/material.dart';

import '../models/profile.dart';

class ProfileProvider extends ChangeNotifier {
  Profile? selectedProfile;

  void select(Profile profile) {
    selectedProfile = profile;
    notifyListeners();
  }
}
