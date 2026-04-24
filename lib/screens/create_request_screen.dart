import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dormitory_app/services/fcm_service.dart';
import 'package:dormitory_app/widgets/custom_widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _descriptionController = TextEditingController();
  final _requestTypes = const ['صيانة', 'نقل', 'شكوى/اقتراح'];

  String? _selectedType = 'صيانة';
  bool _isLoadingUserData = true;
  String? _studentFullName;
  String? _roomNumber;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoadingUserData = false);
      return;
    }

    try {
      final data = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (mounted) {
        setState(() {
          _studentFullName = data.data()?['fullName'] as String?;
          _roomNumber = data.data()?['roomNumber'] as String?;
          _isLoadingUserData = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingUserData = false);
    }
  }

  bool get _canSend =>
      !_isLoadingUserData &&
      _descriptionController.text.isNotEmpty &&
      _studentFullName != null &&
      _roomNumber != null;

  Future<void> _sendRequest() async {
    if (_descriptionController.text.isEmpty) {
      showAppSnackBar(context, 'يرجى كتابة تفاصيل الطلب');
      return;
    }

    if (_studentFullName == null || _roomNumber == null) {
      showAppSnackBar(context, 'تعذر تحميل بيانات الطالب، حاول مجددًا');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    try {
      await FirebaseFirestore.instance.collection('requests').add({
        'type': _selectedType,
        'description': _descriptionController.text.trim(),
        'status': 'جديد',
        'createdAt': FieldValue.serverTimestamp(),
        'uid': user?.uid,
        'studentEmail': user?.email,
        'studentName': _studentFullName,
        'roomNumber': _roomNumber,
      });

      try {
        await FcmService.sendTopicNotification(
          topic: 'admin_alerts',
          title: 'طلب جديد: ${_selectedType ?? 'طلب'}',
          body:
              'تم إرسال ${_selectedType ?? 'طلب'} من ${_studentFullName ?? 'طالب'}',
        );
      } catch (e) {
        debugPrint('FCM admin_alerts send failed: $e');
      }

      if (!mounted) return;
      showAppSnackBar(
        context,
        _selectedType == 'شكوى/اقتراح'
            ? 'تم إرسال الشكوى بنجاح وسيصل تنبيه للإدارة'
            : 'تم إرسال الطلب بنجاح',
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) showAppSnackBar(context, 'حدث خطأ: $e');
    }
  }

  Widget _buildForm() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      sectionTitle('نوع الطلب'),
      const SizedBox(height: 10),
      appDropdownField(
        value: _selectedType,
        labelText: 'اختر نوع الطلب',
        icon: Icons.list_alt,
        values: _requestTypes,
        onChanged: (value) => setState(() => _selectedType = value),
      ),
      const SizedBox(height: 20),
      sectionTitle('تفاصيل الطلب'),
      const SizedBox(height: 10),
      appTextField(
        controller: _descriptionController,
        labelText: 'تفاصيل الطلب',
        icon: Icons.description,
        maxLines: 5,
        hintText: 'اكتب تفاصيل المشكلة هنا...',
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 40),
      appPrimaryButton(
        label: 'إرسال الطلب',
        onPressed: _canSend ? _sendRequest : null,
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.grey[100],
    appBar: AppBar(
      title: const Text('إنشاء طلب جديد'),
      centerTitle: true,
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
    ),
    body: _isLoadingUserData
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildForm(),
          ),
  );
}
