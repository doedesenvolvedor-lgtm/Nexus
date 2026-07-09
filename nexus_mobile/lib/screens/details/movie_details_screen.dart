import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/media.dart';
import '../../providers/favorites_provider.dart';
import '../../widgets/action_buttons.dart';

class MovieDetailsScreen extends StatelessWidget {
  const MovieDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final movie = ModalRoute.of(context)?.settings.arguments as Media?;

    if (movie == null) {
      return const Scaffold(body: Center(child: Text('Conteúdo não encontrado')));
    }

    return Consumer<FavoritesProvider>(
      builder: (context, favoritesProvider, _) {
        return Scaffold(
          body: ListView(
            children: [
              Image.network(
                movie.banner.isNotEmpty ? movie.banner : 'https://via.placeholder.com/800x450',
                height: 260,
                fit: BoxFit.cover,
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie.title,
                      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    ActionButtons(
                      play: () {
                        Navigator.pushNamed(context, '/player', arguments: movie);
                      },
                      favorite: () {
                        favoritesProvider.toggle(movie);
                      },
                      isFavorite: favoritesProvider.contains(movie),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Descrição do filme.',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
