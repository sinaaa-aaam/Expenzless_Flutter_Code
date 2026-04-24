// lib/services/notification_service.dart
// LOCAL RESOURCE 2: Push Notifications
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NotificationService.showRemoteNotification(message);
}

class NotificationService {
  static final _localPlugin = FlutterLocalNotificationsPlugin();
  static final _messaging   = FirebaseMessaging.instance;

  static const _channelBudget = AndroidNotificationChannel(
    'budget_alerts', 'Budget Alerts',
    description: 'Notifications for budget thresholds',
    importance: Importance.high,
  );

  static const _channelGoals = AndroidNotificationChannel(
    'goal_alerts', 'Savings Goals',
    description: 'Notifications for savings goal milestones',
    importance: Importance.defaultImportance,
  );

  static Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _localPlugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    final androidPlugin = _localPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_channelBudget);
    await androidPlugin?.createNotificationChannel(_channelGoals);

    await _messaging.requestPermission(
      alert: true, badge: true, sound: true, provisional: false,
    );

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen((msg) => showRemoteNotification(msg));
  }

  static Future<void> showBudgetAlert({
    required String title, required String body}) async {
    await _localPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title, body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelBudget.id, _channelBudget.name,
          channelDescription: _channelBudget.description,
          importance: Importance.high, priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF0D9488),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true, presentBadge: true, presentSound: true),
      ),
    );
  }

  static Future<void> showGoalComplete({required String title}) async {
    await _localPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '🎉 Savings Goal Reached!',
      'Congratulations! You reached your "$title" goal.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelGoals.id, _channelGoals.name,
          importance: Importance.defaultImportance,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  static Future<void> showRemoteNotification(RemoteMessage message) async {
    final n = message.notification;
    if (n == null) return;
    await _localPlugin.show(
      message.hashCode, n.title ?? 'Expenzless', n.body ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelBudget.id, _channelBudget.name,
          importance: Importance.high),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  static Future<String?> getFcmToken() => _messaging.getToken();
}
