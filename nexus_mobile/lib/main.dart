import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/app.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/trial_provider.dart';
import 'providers/mercadopago_provider.dart';
import 'services/notification_service.dart';
import 'services/trial_notification_service.dart';

// GlobalKey para o Navigator (necessário para notificações)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicializar NotificationService
  await NotificationService().initialize();

  // Inicializar notificações de trial
  await TrialNotificationService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => TrialProvider()),
        ChangeNotifierProvider(create: (_) => MercadoPagoProvider()),
      ],
      child: const NexusApp(),
    ),
  );
}
