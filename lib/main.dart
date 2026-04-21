import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'notification_service.dart';
import 'screens/admin_dashboard.dart';
import 'screens/login_screen.dart';
import 'screens/student_dashboard.dart';

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
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'تطبيق السكن الجامعي',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
        fontFamily: 'Tajawal',
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData) {
            if (snapshot.data!.email == 'admin@test.com') {
              return const Directionality(
                textDirection: TextDirection.rtl,
                child: AdminDashboard(),
              );
            }

            return const Directionality(
              textDirection: TextDirection.rtl,
              child: StudentDashboard(),
            );
          }

          return const Directionality(
            textDirection: TextDirection.rtl,
            child: LoginScreen(),
          );
        },
      ),
    );
  }
}
