import 'package:flutter/material.dart';

import '../../widgets/empty_state_widget.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Downloads')),
      body: EmptyStateWidget(
        icon: Icons.download_done_outlined,
        title: 'Sem downloads salvos',
        message: 'Baixe conteúdos para assistir offline quando quiser.',
      ),
    );
  }
}
