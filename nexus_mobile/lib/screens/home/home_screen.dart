import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/media.dart';
import '../../providers/parental_control_provider.dart';
import '../../providers/profile_provider.dart';
import '../../services/media_service.dart';
import '../../widgets/banner_widget.dart';
import '../../widgets/category_row.dart';
import '../../widgets/continue_card.dart';
import '../../widgets/loading_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final service = MediaService();
  List<Media> movies = [];
  List<Media> series = [];
  bool loading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    load();
  }

Future<void> load() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    // Carrega configurações de Controle Parental do perfil ativo.
    final profileProvider = context.read<ProfileProvider>();
    final profile = profileProvider.selectedProfile;
    final hideAdult = profile != null
        ? await _shouldHideAdultContent(profile.id)
        : false;

    try {
      final responses = await Future.wait([
        service.getMovies(),
        service.getSeries(),
      ]);

      if (!mounted) {
        return;
      }

      var fetchedMovies = responses[0];
      var fetchedSeries = responses[1];

      // Filtra conteúdo +18 / acima da classificação permitida.
      if (profile != null && hideAdult) {
        fetchedMovies = fetchedMovies.where((m) => !_isAdult(m.rating)).toList();
        fetchedSeries = fetchedSeries.where((s) => !_isAdult(s.rating)).toList();
      }

      setState(() {
        movies = fetchedMovies;
        series = fetchedSeries;
        loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        loading = false;
        errorMessage = 'Não foi possível carregar o catálogo agora.';
      });
    }
  }

  /// Verifica se o perfil deve ocultar conteúdo adulto.
  Future<bool> _shouldHideAdultContent(String profileId) async {
    final parental = context.read<ParentalControlProvider>();
    final settings = parental.settings;
    if (settings != null) {
      return settings.hideAdultContent;
    }
    final loaded = await parental.loadSettings(profileId);
    return loaded?.hideAdultContent ?? false;
  }

  /// Indica se a classificação é adulta (+18).
  bool _isAdult(String rating) {
    final normalized = rating.trim().toUpperCase();
    return normalized == '18' || normalized == 'NC-17' || normalized == 'R';
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: LoadingWidget());
    }

    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Nexus')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: load,
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (movies.isEmpty && series.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Nexus')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Nenhum conteúdo disponível no momento.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: load,
                  child: const Text('Atualizar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nexus'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () => Navigator.pushNamed(context, '/favorites'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: ListView(
        children: [
          if (movies.isNotEmpty) BannerWidget(movie: movies.first),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Continuar Assistindo', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ),
                SizedBox(
                  height: 130,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: movies.length > 3 ? 3 : movies.length,
                    itemBuilder: (context, index) {
                      final movie = movies[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: ContinueCard(
                          image: movie.thumbnail.isNotEmpty ? movie.thumbnail : 'https://via.placeholder.com/180x100',
                          progress: 0.4 + (index * 0.1),
                          onTap: () {
                            Navigator.pushNamed(context, '/details', arguments: movie);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          CategoryRow(title: 'Filmes', movies: movies),
          CategoryRow(title: 'Séries', movies: series),
        ],
      ),
    );
  }
}
