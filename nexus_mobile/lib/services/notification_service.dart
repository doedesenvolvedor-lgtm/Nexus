import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';

/// Callback global para mensagens recebidas quando o app está em background
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Handling a background message: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;
  late FlutterLocalNotificationsPlugin _localNotifications;

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Inicializar Local Notifications
      _initializeLocalNotifications();

      // Configurar background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Solicitar permissão de notificações
      await _requestNotificationPermission();

      // Registrar listeners
      _setupMessageHandlers();

      // Registrar device token no backend
      await _registerDeviceToken();

      // Configurar Analytics
      await _setupAnalytics();

      // Configurar Crashlytics
      _setupCrashlytics();

      _isInitialized = true;
      debugPrint('NotificationService inicializado com sucesso');
    } catch (e) {
      debugPrint('Erro ao inicializar NotificationService: $e');
      _crashlytics.recordError(e, StackTrace.current);
    }
  }

  void _initializeLocalNotifications() {
    _localNotifications = FlutterLocalNotificationsPlugin();

    if (Platform.isAndroid) {
      _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              'high_importance_channel',
              'High Importance Notifications',
              description: 'This channel is used for important notifications.',
              importance: Importance.max,
              enableVibration: true,
              enableLights: true,
              showBadge: true,
            ),
          );
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iOSSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iOSSettings,
    );

    _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );
  }

  Future<void> _requestNotificationPermission() async {
    // iOS
    if (Platform.isIOS) {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: true,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('iOS Notification Permission: ${settings.authorizationStatus}');
    }

    // Android 13+
    if (Platform.isAndroid) {
      // Nota: requestNotificationPermission não está disponível nesta versão
      // As permissões são gerenciadas através do Firebase Messaging
    }
  }

  void _setupMessageHandlers() {
    // Mensagens quando o app está em primeiro plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Mensagem recebida em foreground: ${message.notification?.title}');
      _showLocalNotification(message);
      _logNotificationEvent('notification_received_foreground', message);
    });

    // Mensagens quando o app é aberto a partir de uma notificação
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notificação clicada: ${message.notification?.title}');
      _handleNotificationClick(message);
      _logNotificationEvent('notification_opened', message);
    });
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;

    if (notification == null) return;

    try {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'This channel is used for important notifications.',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker',
            enableVibration: true,
            enableLights: true,
          ),
          iOS: DarwinNotificationDetails(
            sound: 'default',
            presentSound: true,
            presentAlert: true,
            presentBadge: true,
          ),
        ),
        payload: message.data.toString(),
      );
    } catch (e) {
      debugPrint('Erro ao mostrar notificação local: $e');
    }
  }

  void _handleNotificationTap(NotificationResponse response) {
    debugPrint('Notificação clicada: ${response.id}');
    // Adicione aqui a lógica para navegar para a tela apropriada
  }

  void _handleNotificationClick(RemoteMessage message) {
    debugPrint('Processando clique na notificação: ${message.notification?.title}');
    // Adicione aqui a lógica para navegar com base no conteúdo da mensagem
    final data = message.data;
    if (data.containsKey('screen')) {
      // Navegar para a tela especificada
      // Navigator.of(context).pushNamed(data['screen']);
    }
  }

  Future<void> _registerDeviceToken() async {
    try {
      final token = await _firebaseMessaging.getToken();

      if (token == null) {
        debugPrint('Falha ao obter device token');
        return;
      }

      debugPrint('Device Token: $token');

      // Salvar token localmente
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('device_token', token);

      // Enviar token para backend
      // Isso deve ser feito após o usuário fazer login
      if (navigatorKey.currentContext != null) {
        // Aqui você pode enviar o token para o backend
        // await AuthProvider.registerDeviceToken(token);
      }

      // Listener para quando o token é renovado
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        debugPrint('Device Token renovado: $newToken');
        await prefs.setString('device_token', newToken);
        // Enviar novo token para backend
        // await AuthProvider.registerDeviceToken(newToken);
      });
    } catch (e) {
      debugPrint('Erro ao registrar device token: $e');
      _crashlytics.recordError(e, StackTrace.current);
    }
  }

  Future<void> _setupAnalytics() async {
    try {
      // Habilitar coleta de dados analíticos
      await _analytics.setAnalyticsCollectionEnabled(true);

      // Definir user ID se disponível
      // await _analytics.setUserId(id: userId);

      debugPrint('Firebase Analytics inicializado');
    } catch (e) {
      debugPrint('Erro ao configurar Analytics: $e');
    }
  }

  void _setupCrashlytics() {
    try {
      // Habilitar coleta automática de erros
      FlutterError.onError = (errorDetails) {
        _crashlytics.recordFlutterError(errorDetails);
      };

      // Para erros não capturados
      PlatformDispatcher.instance.onError = (error, stack) {
        _crashlytics.recordError(error, stack, fatal: true);
        return true;
      };

      debugPrint('Firebase Crashlytics inicializado');
    } catch (e) {
      debugPrint('Erro ao configurar Crashlytics: $e');
    }
  }

  void _logNotificationEvent(String eventName, RemoteMessage message) {
    try {
      _analytics.logEvent(
        name: eventName,
        parameters: {
          'title': message.notification?.title ?? 'N/A',
          'body': message.notification?.body ?? 'N/A',
          'data': message.data.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('Erro ao logar evento de notificação: $e');
    }
  }

  /// Métodos públicos para uso na aplicação

  /// Log de evento personalizado (ex: user_signup, video_played, etc)
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (e) {
      debugPrint('Erro ao logar evento: $e');
    }
  }

  /// Log de tela visitada
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
    } catch (e) {
      debugPrint('Erro ao logar screen view: $e');
    }
  }

  /// Registrar erro não fatal
  void recordException(dynamic exception, StackTrace? stackTrace) {
    try {
      _crashlytics.recordError(exception, stackTrace ?? StackTrace.current);
    } catch (e) {
      debugPrint('Erro ao registrar exceção: $e');
    }
  }

  /// Definir custom key para Crashlytics
  void setCrashlyticsCustomKey(String key, Object value) {
    try {
      _crashlytics.setCustomKey(key, value);
    } catch (e) {
      debugPrint('Erro ao definir custom key: $e');
    }
  }

  /// Definir user ID para tracking
  Future<void> setUserId(String userId) async {
    try {
      await _analytics.setUserId(id: userId);
      _crashlytics.setUserIdentifier(userId);
    } catch (e) {
      debugPrint('Erro ao definir user ID: $e');
    }
  }

  /// Registrar device token no backend
  Future<void> registerDeviceTokenWithBackend({
    required String deviceToken,
    String? deviceName,
  }) async {
    try {
      // Esta função deve ser chamada após fazer login
      // e deve usar o seu cliente HTTP para enviar para o backend
      debugPrint('Device token registrado no backend: $deviceToken');
    } catch (e) {
      debugPrint('Erro ao registrar device token no backend: $e');
      _crashlytics.recordError(e, StackTrace.current);
    }
  }
}

