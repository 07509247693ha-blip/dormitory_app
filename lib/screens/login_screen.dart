import 'package:dormitory_app/screens/admin_dashboard.dart';
import 'package:dormitory_app/screens/signup_screen.dart';
import 'package:dormitory_app/screens/student_dashboard.dart';
import 'package:dormitory_app/utils/helpers.dart';
import 'package:dormitory_app/widgets/custom_widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

//"استخدمته هنا لأن الشاشة تتغير؛ فعندما يضغط المستخدم على (دخول)، تظهر دائرة تحميل وتختفي الأزرار، وهذا يتطلب تغيير الـ (State).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

//(Controller)التقاط النص من المستخدم
class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  //اظهار دائرة تحميل لمنع المستخدم من الضغط مرتين
  bool _isLoading = false;

//دخول السيرفر
  Future<void> _authenticate({required bool asAdmin}) async {
    setState(() => _isLoading = true);
    final email = _emailController.text.trim(); //ترفض الطلب اذا ادخل ايميل فارغ 

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: _passwordController.text.trim(),
      );

//هنا يتأكد هل المسجل مسؤول ام طالب
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
        //اذا نجح ننتقل الى الواجهة الاخرى
        pushReplacementScreen( // إجراء أمني  لكي يقوم(تدمير) شاشة تسجيل الدخول من ذاكرة الهاتف بمجرد دخول الطالب
          context,
          asAdmin ? const AdminDashboard() : const StudentDashboard(),
        );
      }
    } on FirebaseAuthException catch (e) {
      // يتأكد من صحة الرمز و اليميل 
      if (mounted) {
        String errorMessage;
        if (e.code == 'invalid-email') {
          errorMessage = 'صيغة البريد الإلكتروني غير صحيحة.';
        } else if (e.code == 'user-not-found' ||
            e.code == 'wrong-password' ||
            e.code == 'invalid-credential') {
          errorMessage = 'البريد الإلكتروني أو كلمة المرور غير صحيحة.';
        } else if (e.code == 'user-disabled') {
          errorMessage = 'تم حظر هذا الحساب من قبل الإدارة.';
        } else {
          errorMessage = 'حدث خطأ أثناء تسجيل الدخول، يرجى المحاولة لاحقاً.';
        }
        showAppSnackBar(context, errorMessage);
      }
    } finally {
      //عند الضغط على تسجيل الدخول تستدعا setState 
      if (mounted) setState(() => _isLoading = false); //إجبار دالة(build) على إعادة رسم الواجهة لكي تظهر  (دائرة التحميل) بدلاً من نص الزر العادي.
    }
  }

//واجهة المستخدم
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
                  appTextField( //مربوطات ب (Controllers)ياخذا المعلومات من اليوزر ويدزنهة للفايربيس
                    controller: _emailController,
                    labelText: 'البريد الإلكتروني',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress, //كيبورد خاص لليميلات من اجل تسهيل الكتابة @
                  ),
                  const SizedBox(height: 20),
                  appTextField( // ستخدمنة appTextField بدل TextField من اجل تقليل التكرار
                    controller: _passwordController,
                    labelText: 'كلمة المرور',
                    icon: Icons.lock,
                    obscureText: true, //تحويل النص الى نقاط
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
                    onPressed: () => Navigator.push( //استخدمنة بوش حتى نخليهة بلاستاك ونعرضهة فوك لوحة تسجيل الدخول ومن نسوي رجوع تلقئيا يسوي بوب
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