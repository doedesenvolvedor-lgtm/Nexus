import 'package:flutter/material.dart';

class DownloadCard extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const DownloadCard({super.key, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      leading: const Icon(Icons.download_done),
      onTap: onTap,
    );
  }
}
