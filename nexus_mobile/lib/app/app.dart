import 'package:flutter/material.dart';

import '../main.dart';
import 'theme.dart';
import 'routes.dart';

class NexusApp extends StatelessWidget {
  const NexusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nexus Streaming',
      theme: nexusTheme,
      initialRoute: '/',
      routes: routes,
      navigatorKey: navigatorKey,
    );
  }
}
