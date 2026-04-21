import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    try {
      // 1. طلب الصلاحية
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('تم منح صلاحية الإشعارات ✅');
        
        try {
          String? token = await _messaging.getToken();
          print('FCM Token: $token');
        } catch (e) {
          print('تحذير: لم نتمكن من جلب Token على المتصفح: $e');
        }

        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          print('وصل إشعار من السحاب: ${message.notification?.title}');
        });
      }
    } catch (e) {
      print("⚠️ مشكلة في تشغيل الإشعارات: $e");
    }
  }

  // دالة الإشعار المحلي
  Future<void> showInstantNotification(String title, String body) async {
    // على المتصفح، النظام يمنع النوافذ المنبثقة المباشرة، لذا نكتفي بالطباعة
    // وسنعتمد على الـ SnackBar الذي أضفناه في شاشة الإرسال ليعرف الطالب بنجاح العملية
    print("🔔 تنبيه تم تنفيذه: $title - $body");
  }
}