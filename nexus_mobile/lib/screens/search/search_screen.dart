import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/media.dart';
import '../../services/search_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final searchService = SearchService();
  final controller = TextEditingController();
  List<Media> results = [];
  bool loading = false;

  Future<void> _search(String text) async {
    if (text.trim().isEmpty) {
      setState(() => results = []);
      return;
    }

    setState(() => loading = true);
    final items = await searchService.search(text);
    if (!mounted) return;
    setState(() {
      results = items;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pesquisar')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: controller,
              onChanged: _search,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Pesquisar filmes...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (loading) const CircularProgressIndicator(),
            if (!loading && results.isEmpty && controller.text.isNotEmpty)
              const Text('Nenhum resultado encontrado'),
            Expanded(
              child: ListView.builder(
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final media = results[index];
                  return ListTile(
                    leading: CachedNetworkImage(
                      imageUrl: media.thumbnail.isNotEmpty ? media.thumbnail : 'https://via.placeholder.com/80',
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    ),
                    title: Text(media.title),
                    subtitle: Text(media.type),
                    onTap: () => Navigator.pushNamed(context, '/details', arguments: media),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
