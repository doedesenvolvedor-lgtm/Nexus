import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final service = SettingsService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final dark = await service.loadTheme();
    if (!mounted) return;
    context.read<SettingsProvider>().changeTheme(dark);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final profile = context.watch<ProfileProvider>().selectedProfile;

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        children: [
          if (profile != null)
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(profile.name),
              subtitle: const Text('Perfil ativo'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(context, '/edit-profile'),
            ),
          SwitchListTile(
            value: settings.darkMode,
            title: const Text('Tema Escuro'),
            onChanged: (value) {
              settings.changeTheme(value);
              service.saveTheme(value);
            },
          ),
          SwitchListTile(
            value: settings.notifications,
            title: const Text('Notificações'),
            onChanged: settings.toggleNotifications,
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Idioma'),
            subtitle: Text(settings.language),
            onTap: () {
              settings.changeLanguage(settings.language == 'pt-BR' ? 'en-US' : 'pt-BR');
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Controle Parental'),
            onTap: () => Navigator.pushNamed(context, '/parental'),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sair'),
            onTap: () {
              context.read<AuthProvider>().logout();
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
    );
  }
}
