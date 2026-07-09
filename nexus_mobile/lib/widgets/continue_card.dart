import 'package:flutter/material.dart';

class ContinueCard extends StatelessWidget {
  final String image;
  final double progress;
  final VoidCallback onTap;

  const ContinueCard({
    super.key,
    required this.image,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Image.network(
            image,
            width: 180,
            height: 100,
            fit: BoxFit.cover,
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(value: progress),
        ],
      ),
    );
  }
}
