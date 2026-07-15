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
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.favorite_border, size: 48),
                    const SizedBox(height: 12),
                    const Text('Você ainda não adicionou favoritos.'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/home'),
                      child: const Text('Explorar catálogo'),
                    ),
                  ],
                ),
              ),
            );
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
