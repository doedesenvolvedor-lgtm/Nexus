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

  // Inicializar Firebase com fallback seguro
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    // Firebase não configurado - app funciona sem notificações push
    debugPrint('Firebase initialization skipped: $e');
  }

  // Inicializar NotificationService com fallback
  try {
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('NotificationService initialization skipped: $e');
  }

  // Inicializar notificações de trial com fallback
  try {
    await TrialNotificationService.initialize();
  } catch (e) {
    debugPrint('TrialNotificationService initialization skipped: $e');
  }

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
