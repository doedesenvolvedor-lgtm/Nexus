import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/favorites_provider.dart';
import '../../widgets/empty_state_widget.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos')),
      body: Consumer<FavoritesProvider>(
        builder: (context, favoritesProvider, _) {
          if (favoritesProvider.favorites.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.favorite_border,
              title: 'Nenhum favorito ainda',
              message: 'Salve filmes e séries para encontrar tudo aqui depois.',
              buttonLabel: 'Explorar catálogo',
              onButtonPressed: () => Navigator.pushNamed(context, '/home'),
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
