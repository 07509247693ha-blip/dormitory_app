import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dormitory_app/fcm_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  String? _selectedType = 'صيانة';
  final TextEditingController _descriptionController = TextEditingController();
  final List<String> _requestTypes = ['صيانة', 'نقل', 'شكوى/اقتراح'];

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
      if (mounted) {
        setState(() {
          _isLoadingUserData = false;
        });
      }
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = userDoc.data();

      if (!mounted) {
        return;
      }

      setState(() {
        _studentFullName = data?['fullName'] as String?;
        _roomNumber = data?['roomNumber'] as String?;
        _isLoadingUserData = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingUserData = false;
      });
    }
  }

  void _sendRequest() async {
    if (_isLoadingUserData) {
      return;
    }

    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('يرجى كتابة تفاصيل الطلب')));
      return;
    }

    if (_studentFullName == null || _roomNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر تحميل بيانات الطالب، حاول مجددًا')),
      );
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

      if (!mounted) {
        return;
      }

      final isComplaint = _selectedType == 'شكوى/اقتراح';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isComplaint
                ? 'تم إرسال الشكوى بنجاح وسيصل تنبيه للإدارة'
                : 'تم إرسال الطلب بنجاح',
          ),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'نوع الطلب',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedType,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: _requestTypes
                        .map(
                          (type) =>
                              DropdownMenuItem(value: type, child: Text(type)),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _selectedType = value),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'تفاصيل الطلب',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'اكتب تفاصيل المشكلة هنا...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _sendRequest,
                      child: const Text(
                        'إرسال الطلب',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
