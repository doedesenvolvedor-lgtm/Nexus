import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/favorites_provider.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos')),
      body: Consumer<FavoritesProvider>(
        builder: (context, favoritesProvider, _) {
          if (favoritesProvider.favorites.isEmpty) {
            return const Center(child: Text('Lista de favoritos'));
          }

          return ListView.builder(
            itemCount: favoritesProvider.favorites.length,
            itemBuilder: (context, index) {
              final movie = favoritesProvider.favorites[index];
              return ListTile(
                title: Text(movie.title),
                subtitle: Text(movie.type),
                onTap: () {
                  Navigator.pushNamed(context, '/details', arguments: movie);
                },
              );
            },
          );
        },
      ),
    );
  }
}
