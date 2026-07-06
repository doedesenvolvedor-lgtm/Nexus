import 'package:flutter/material.dart';

import '../models/media.dart';

class MovieCard extends StatelessWidget {
  final Media movie;
  final VoidCallback onTap;

  const MovieCard({
    super.key,
    required this.movie,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            movie.thumbnail.isNotEmpty ? movie.thumbnail : 'https://via.placeholder.com/300x450',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
