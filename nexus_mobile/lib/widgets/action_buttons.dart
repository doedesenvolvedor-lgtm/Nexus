import 'package:flutter/material.dart';

class ActionButtons extends StatelessWidget {
  final VoidCallback play;
  final VoidCallback favorite;
  final bool isFavorite;

  const ActionButtons({
    super.key,
    required this.play,
    required this.favorite,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: play,
          icon: const Icon(Icons.play_arrow),
          label: const Text('Assistir'),
        ),
        const SizedBox(width: 15),
        ElevatedButton.icon(
          onPressed: favorite,
          icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
          label: const Text('Favorito'),
        ),
      ],
    );
  }
}
