import 'package:dormitory_app/screens/admin_dashboard.dart';
import 'package:dormitory_app/screens/signup_screen.dart';
import 'package:dormitory_app/screens/student_dashboard.dart';
import 'package:dormitory_app/utils/helpers.dart';
import 'package:dormitory_app/widgets/custom_widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _authenticate({required bool asAdmin}) async {
    setState(() => _isLoading = true);
    final email = _emailController.text.trim();

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: _passwordController.text.trim(),
      );

      if (isAdminEmail(email) != asAdmin) {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          showAppSnackBar(
            context,
            asAdmin
                ? 'عذراً، هذا الحساب لا يملك صلاحيات الإدارة'
                : 'عذراً، هذا الحساب مخصص للإدارة. يرجى استخدام زر (دخول كمسؤول)',
          );
        }
        return;
      }

      if (mounted) {
        pushReplacementScreen(
          context,
          asAdmin ? const AdminDashboard() : const StudentDashboard(),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        showAppSnackBar(context, e.message ?? 'حدث خطأ أثناء تسجيل الدخول');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.grey[100],
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            children: [
              authHeader('تسجيل الدخول'),
              const SizedBox(height: 40),
              appTextField(
                controller: _emailController,
                labelText: 'البريد الإلكتروني',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              appTextField(
                controller: _passwordController,
                labelText: 'كلمة المرور',
                icon: Icons.lock,
                obscureText: true,
              ),
              const SizedBox(height: 30),
              appPrimaryButton(
                label: 'دخول كطالب',
                isLoading: _isLoading,
                onPressed: _isLoading
                    ? null
                    : () => _authenticate(asAdmin: false),
              ),
              const SizedBox(height: 15),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SignupScreen()),
                ),
                child: const Text(
                  'إنشاء حساب جديد',
                  style: TextStyle(color: Colors.blue, fontSize: 16),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () => _authenticate(asAdmin: true),
                child: const Text(
                  'دخول كمسؤول',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
