import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/media.dart';
import '../../providers/favorites_provider.dart';
import '../../services/media_service.dart';
import '../../widgets/action_buttons.dart';

class MovieDetailsScreen extends StatefulWidget {
  const MovieDetailsScreen({super.key});

  @override
  State<MovieDetailsScreen> createState() => _MovieDetailsScreenState();
}

class _MovieDetailsScreenState extends State<MovieDetailsScreen> {
  final _mediaService = MediaService();
  Media? _media;
  bool _loading = true;
  bool _notFound = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loading) {
      _loadDetails();
    }
  }

  Future<void> _loadDetails() async {
    final routeMedia = ModalRoute.of(context)?.settings.arguments as Media?;
    if (routeMedia == null) {
      setState(() {
        _loading = false;
        _notFound = true;
      });
      return;
    }

    final details = await _mediaService.getDetails(routeMedia.id);
    if (!mounted) {
      return;
    }

    setState(() {
      _media = details ?? routeMedia;
      _loading = false;
      _notFound = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_notFound || _media == null) {
      return const Scaffold(body: Center(child: Text('Conteúdo não encontrado')));
    }

    final movie = _media!;
    final metadata = <String>[
      if (movie.type.isNotEmpty) movie.type.toUpperCase(),
      if (movie.releaseYear != null) movie.releaseYear.toString(),
      if (movie.genre.isNotEmpty) movie.genre,
      if (movie.rating.isNotEmpty) movie.rating,
      if (movie.duration != null) '${movie.duration} min',
    ];

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
                    if (metadata.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          metadata.join(' • '),
                          style: const TextStyle(fontSize: 14, color: Colors.white70),
                        ),
                      ),
                    const SizedBox(height: 20),
                    Text(
                      movie.description.isNotEmpty ? movie.description : 'Descrição indisponível.',
                      style: const TextStyle(fontSize: 16),
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
