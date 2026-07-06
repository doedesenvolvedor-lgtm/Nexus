import 'package:flutter/material.dart';

import '../../models/profile.dart';
import '../../services/profile_service.dart';
import '../../widgets/profile_avatar.dart';

class ProfileSelectionScreen extends StatefulWidget {
  const ProfileSelectionScreen({super.key});

  @override
  State<ProfileSelectionScreen> createState() => _ProfileSelectionScreenState();
}

class _ProfileSelectionScreenState extends State<ProfileSelectionScreen> {
  final service = ProfileService();
  List<Profile> profiles = [];

  @override
  void initState() {
    super.initState();
    loadProfiles();
  }

  Future loadProfiles() async {
    const token = 'JWT_AQUI';
    profiles = await service.getProfiles(token);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quem está assistindo?')),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: profiles.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
        ),
        itemBuilder: (context, index) {
          final profile = profiles[index];
          return ProfileAvatar(
            image: profile.avatarUrl,
            name: profile.name,
            onTap: () {
              Navigator.pushNamed(context, '/home', arguments: profile);
            },
          );
        },
      ),
    );
  }
}
