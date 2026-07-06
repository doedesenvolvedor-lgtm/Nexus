import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nexus')), 
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text('Em alta', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          Placeholder(fallbackHeight: 180),
          SizedBox(height: 24),
          Text('Continue assistindo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          Placeholder(fallbackHeight: 120),
        ],
      ),
    );
  }
}
