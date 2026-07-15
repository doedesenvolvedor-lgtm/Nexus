import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

class TrialNotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();
  static const String _channelId = 'trial_notifications';
  static const String _channelName = 'Notificações de Trial';

  static Future<void> initialize() async {
    const settingsAndroid = AndroidInitializationSettings('@app_icon');
    const settingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _notifications.initialize(
      const InitializationSettings(
        android: settingsAndroid,
        iOS: settingsIOS,
      ),
    );

    // Criar canal de notificação
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: 'Notificações sobre o período de trial',
            importance: Importance.high,
          ),
        );
  }

  static Future<void> scheduleTrialNotifications(
    DateTime trialEndsAt,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    // Notificação no dia 2 (se ainda não foi enviada)
    final day2Notification = trialEndsAt.subtract(const Duration(days: 1));
    if (DateTime.now().isBefore(day2Notification)) {
      final hasNotified = prefs.getBool('trial_day2_notified') ?? false;
      if (!hasNotified) {
        final tzDay2 = tz.TZDateTime.from(day2Notification, tz.local);
        await _notifications.zonedSchedule(
          1,
          '🎬 Seu trial termina amanhã!',
          'Aproveite o último dia de acesso Premium ao Nexus.',
          tzDay2,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              channelDescription:
                  'Notificações sobre o período de trial',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dateAndTime,
        );
        await prefs.setBool('trial_day2_notified', true);
      }
    }

    // Notificação no último dia (se ainda não foi enviada)
    final lastDayNotification = trialEndsAt.subtract(const Duration(hours: 2));
    if (DateTime.now().isBefore(lastDayNotification)) {
      final hasNotified = prefs.getBool('trial_lastday_notified') ?? false;
      if (!hasNotified) {
        final tzLastDay = tz.TZDateTime.from(lastDayNotification, tz.local);
        await _notifications.zonedSchedule(
          2,
          '⏰ Seu trial termina hoje às ${trialEndsAt.hour}:${trialEndsAt.minute.toString().padLeft(2, '0')}',
          'Escolha um plano para continuar assistindo seus favoritos.',
          tzLastDay,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              channelDescription:
                  'Notificações sobre o período de trial',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dateAndTime,
        );
        await prefs.setBool('trial_lastday_notified', true);
      }
    }

    // Notificação quando expira (se ainda não foi enviada)
    if (DateTime.now().isBefore(trialEndsAt)) {
      final hasNotified = prefs.getBool('trial_expired_notified') ?? false;
      if (!hasNotified) {
        final tzTrialEnd = tz.TZDateTime.from(trialEndsAt, tz.local);
        await _notifications.zonedSchedule(
          3,
          '😢 Seu trial expirou',
          'Escolha um plano para continuar assistindo.',
          tzTrialEnd,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              channelDescription:
                  'Notificações sobre o período de trial',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dateAndTime,
        );
        await prefs.setBool('trial_expired_notified', true);
      }
    }
  }

  static Future<void> showInstantNotification(
    String title,
    String body,
  ) async {
    await _notifications.show(
      0,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Notificações sobre o período de trial',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  static Future<void> cancelNotifications() async {
    await _notifications.cancelAll();
  }

  static Future<void> resetNotificationFlags() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('trial_day2_notified');
    await prefs.remove('trial_lastday_notified');
    await prefs.remove('trial_expired_notified');
  }
}
