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

  final _complexes = const [
    'المجمع الأول - الحوت',
    'المجمع الثاني - صيدنايا',
    'المجمع الثالث - ابو غريب',
    'المجمع الرابع - التاجي',
    'المجمع الخامس - زويرا',
    'المجمع السادس - بادوش',
    'المجمع السابع - بوكا',
  ];
  final _buildings = const ['1', '2', '3', '4', '5', '6', '7'];
  final _sectors = const ['أ', 'ب', 'ج', 'د'];

  String _selectedComplex = 'المجمع الأول - الحوت';
  String _selectedBuilding = '1';
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
            'complexName': _selectedComplex,
            'buildingNumber': _selectedBuilding,
            'sector': _selectedSector,
            'floorLevel': getFloorLevel(roomNumber),
            'createdAt': FieldValue.serverTimestamp(),
          });

      if (mounted) showAppSnackBar(context, 'تم إنشاء الحساب بنجاح');
      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        showAppSnackBar(context, e.message ?? 'حدث خطأ أثناء إنشاء الحساب');
      }
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
              labelText: 'المجمع',
              icon: Icons.location_city,
              values: _complexes,
              onChanged: (value) => setState(() => _selectedComplex = value!),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: appDropdownField(
                    value: _selectedBuilding,
                    labelText: 'المبنى',
                    icon: Icons.business,
                    values: _buildings,
                    onChanged: (value) =>
                        setState(() => _selectedBuilding = value!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: appDropdownField(
                    value: _selectedSector,
                    labelText: 'القطاع',
                    icon: Icons.grid_view,
                    values: _sectors,
                    onChanged: (value) =>
                        setState(() => _selectedSector = value!),
                  ),
                ),
              ],
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
