import 'package:flutter/material.dart';

import '../models/media.dart';
import 'movie_card.dart';

class CategoryRow extends StatelessWidget {
  final String title;
  final List<Media> movies;

  const CategoryRow({
    super.key,
    required this.title,
    required this.movies,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 210,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: movies.length,
            itemBuilder: (context, index) {
              return MovieCard(
                movie: movies[index],
                onTap: () {
                  Navigator.pushNamed(context, '/details', arguments: movies[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
