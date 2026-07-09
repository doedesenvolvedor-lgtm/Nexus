import 'package:flutter/material.dart';

import '../models/media.dart';

class FavoritesProvider extends ChangeNotifier {
  final List<Media> favorites = [];

  void add(Media movie) {
    final exists = favorites.any((item) => item.id == movie.id);
    if (!exists) {
      favorites.add(movie);
      notifyListeners();
    }
  }

  void remove(Media movie) {
    favorites.removeWhere((item) => item.id == movie.id);
    notifyListeners();
  }

  void toggle(Media movie) {
    if (contains(movie)) {
      remove(movie);
    } else {
      add(movie);
    }
  }

  bool contains(Media movie) {
    return favorites.any((item) => item.id == movie.id);
  }
}
