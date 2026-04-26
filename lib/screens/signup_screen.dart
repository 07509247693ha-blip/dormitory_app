import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dormitory_app/utils/helpers.dart';
import 'package:dormitory_app/widgets/custom_widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _roomNumberController = TextEditingController();
  final _passwordController = TextEditingController();

  // هندسة البيانات: ربط اسم المجمع برقم المبنى مباشرة
  final Map<String, String> _complexData = const {
    'المجمع الأول - الحوت': '1',
    'المجمع الثاني - صيدنايا': '2',
    'المجمع الثالث - ابو غريب': '3',
    'المجمع الرابع - التاجي': '4',
    'المجمع الخامس - زويرا': '5',
    'المجمع السادس - بادوش': '6',
    'المجمع السابع - بوكا': '7',
  };
  
  final _sectors = const ['أ', 'ب', 'ج', 'د'];

  String _selectedComplex = 'المجمع الأول - الحوت';
  String _selectedSector = 'أ';
  bool _isLoading = false;

  String get _floorLevel => getFloorLevel(_roomNumberController.text.trim());

  Future<void> _signUp() async {
    setState(() => _isLoading = true);

    try {
      final roomNumber = _roomNumberController.text.trim();
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
            'uid': credential.user!.uid,
            'fullName': _fullNameController.text.trim(),
            'email': _emailController.text.trim(),
            'roomNumber': roomNumber,
            'complexName': _selectedComplex, // اسم المجمع
            'buildingNumber': _complexData[_selectedComplex], // رقم المبنى يسحب تلقائياً
            'sector': _selectedSector,
            'floorLevel': getFloorLevel(roomNumber),
            'createdAt': FieldValue.serverTimestamp(),
          });

      if (mounted) showAppSnackBar(context, 'تم إنشاء الحساب بنجاح');
      if (mounted) Navigator.pop(context);

    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String errorMessage;
        
        // هنا يتم فحص رمز الخطأ القادم من السيرفر وعرض مقابله بالعربي
        if (e.code == 'email-already-in-use') {
          errorMessage = 'هذا البريد الإلكتروني مستخدم بالفعل لحساب آخر.';
        } else if (e.code == 'weak-password') {
          errorMessage = 'كلمة المرور ضعيفة جداً، يرجى اختيار كلمة أقوى.';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'صيغة البريد الإلكتروني غير صحيحة.';
        } else {
          // في حال وجود خطأ آخر غير متوقع من فايربيس
          errorMessage = 'حدث خطأ أثناء إنشاء الحساب: ${e.message}';
        }
        
        showAppSnackBar(context, errorMessage);
      }
    } catch (e) {
      // صيد الأخطاء العامة التي ليست من فايربيس
      if (mounted) showAppSnackBar(context, 'حدث خطأ غير متوقع، حاول مجدداً');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.grey[100],
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            authHeader('إنشاء حساب جديد'),
            const SizedBox(height: 40),
            appTextField(
              controller: _fullNameController,
              labelText: 'الاسم الكامل',
              icon: Icons.person,
            ),
            const SizedBox(height: 20),
            appTextField(
              controller: _emailController,
              labelText: 'البريد الإلكتروني',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            appDropdownField(
              value: _selectedComplex,
              labelText: 'المجمع / المبنى', // تم تحديث التسمية
              icon: Icons.location_city,
              values: _complexData.keys.toList(), // جلب المفاتيح (أسماء المجمعات)
              onChanged: (value) => setState(() => _selectedComplex = value!),
            ),
            const SizedBox(height: 20),
            appDropdownField(
              value: _selectedSector,
              labelText: 'القطاع',
              icon: Icons.grid_view,
              values: _sectors,
              onChanged: (value) => setState(() => _selectedSector = value!),
            ),
            const SizedBox(height: 20),
            appTextField(
              controller: _roomNumberController,
              labelText: 'رقم الغرفة',
              icon: Icons.meeting_room,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'الطابق: $_floorLevel',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
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
              label: 'إنشاء الحساب',
              isLoading: _isLoading,
              onPressed: _isLoading ? null : _signUp,
            ),
            const SizedBox(height: 15),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'لدي حساب بالفعل',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}