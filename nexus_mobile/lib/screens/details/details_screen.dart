import 'package:flutter/material.dart';

import '../../models/media.dart';

class DetailsScreen extends StatelessWidget {
  const DetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final media = ModalRoute.of(context)?.settings.arguments as Media?;

    return Scaffold(
      appBar: AppBar(title: Text(media?.title ?? 'Detalhes')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (media != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  media.banner.isNotEmpty ? media.banner : 'https://via.placeholder.com/800x450',
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 16),
            Text(
              media?.title ?? 'Título indisponível',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(media?.type ?? 'Conteúdo'),
            const SizedBox(height: 20),
            const Text('Essa tela será expandida com player, descrição e episódios em seguida.'),
          ],
        ),
      ),
    );
  }
}
