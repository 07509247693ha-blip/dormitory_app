import 'package:dormitory_app/firebase_options.dart';
import 'package:dormitory_app/services/notification_service.dart';
import 'package:dormitory_app/screens/admin_dashboard.dart';
import 'package:dormitory_app/screens/login_screen.dart';
import 'package:dormitory_app/screens/student_dashboard.dart';
import 'package:dormitory_app/utils/helpers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  try {
    if (!kIsWeb) {
      await NotificationService.instance.initNotification();
    }
  } catch (e) {
    debugPrint('تنبيه: تعذر تهيئة الإشعارات: $e');
  }

  runApp(const DormitoryApp());
}

class DormitoryApp extends StatelessWidget {
  const DormitoryApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'تطبيق السكن الجامعي',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      useMaterial3: true,
      fontFamily: 'Tajawal',
    ),
    home: StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (_, snapshot) =>
          snapshot.connectionState == ConnectionState.waiting
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : Directionality(
              textDirection: TextDirection.rtl,
              child: snapshot.data == null
                  ? const LoginScreen()
                  : isAdminEmail(snapshot.data!.email)
                  ? const AdminDashboard()
                  : const StudentDashboard(),
            ),
    ),
  );
}
