import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();

  static final instance = NotificationService._();
  final _notifications = FlutterLocalNotificationsPlugin();

  Future<void> initNotification() async {
    await _notifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    await FirebaseMessaging.instance.requestPermission();
    debugPrint('FCM Token: ${await FirebaseMessaging.instance.getToken()}');
    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification != null) {
        showNotification(
          title: notification.title ?? 'إشعار جديد',
          body: notification.body ?? '',
        );
      }
    });
  }

  Future<void> showNotification({
    required String title,
    required String body,
  }) => _notifications.show(
    id: 0,
    title: title,
    body: body,
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        'dormitory_channel',
        'Dormitory Notifications',
        channelDescription: 'Notifications for the dormitory application',
        importance: Importance.max,
        priority: Priority.high,
      ),
    ),
  );
}
