import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  final String image;
  final String name;
  final VoidCallback onTap;

  const ProfileAvatar({
    super.key,
    required this.image,
    required this.name,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 45,
            backgroundImage: NetworkImage(image.isNotEmpty ? image : 'https://via.placeholder.com/150'),
          ),
          const SizedBox(height: 10),
          Text(name),
        ],
      ),
    );
  }
}
