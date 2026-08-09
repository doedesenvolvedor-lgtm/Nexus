import 'package:flutter/material.dart';

import '../../widgets/empty_state_widget.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notificações')),
      body: EmptyStateWidget(
        icon: Icons.notifications_none_outlined,
        title: 'Nenhuma novidade por aqui',
        message: 'Você será avisado quando houver lançamentos e novidades.',
      ),
    );
  }
}
