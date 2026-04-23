import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dormitory_app/fcm_service.dart';
import 'package:dormitory_app/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final TextEditingController _announcementTitleController =
      TextEditingController();
  final TextEditingController _announcementBodyController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      FirebaseMessaging.instance.subscribeToTopic('admin_alerts');
    }
  }

  void _updateStatus(String docId, String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('requests').doc(docId).update(
        {'status': newStatus},
      );
    } catch (e) {
      print('خطأ في التحديث: $e');
    }
  }

  Future<void> _deleteRequest(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(docId)
          .delete();
    } catch (e) {
      print('خطأ في الحذف: $e');
    }
  }

  Future<void> _confirmDelete(BuildContext context, String docId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: const Text('هل أنت متأكد من حذف هذا الطلب؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await _deleteRequest(docId);
    }
  }

  Future<void> _publishAnnouncement() async {
    final title = _announcementTitleController.text.trim();
    final body = _announcementBodyController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('announcements').add({
        'title': title,
        'body': body,
        'createdAt': FieldValue.serverTimestamp(),
      });

      try {
        await FcmService.sendTopicNotification(
          topic: 'announcements',
          title: title,
          body: body,
        );
      } catch (e) {
        debugPrint('FCM announcements send failed: $e');
      }
    } catch (e) {
      print('خطأ في نشر الإعلان: $e');
    }
  }

  Future<void> _showAnnouncementDialog() async {
    _announcementTitleController.clear();
    _announcementBodyController.clear();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('نشر إعلان جديد'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _announcementTitleController,
                  decoration: const InputDecoration(labelText: 'عنوان الإعلان'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _announcementBodyController,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'نص الإعلان'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () async {
                await _publishAnnouncement();
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('نشر'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickScheduledDate(BuildContext context, String docId) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (selectedDate == null) {
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('requests').doc(docId).update(
        {'scheduledDate': Timestamp.fromDate(selectedDate)},
      );
    } catch (e) {
      print('خطأ في تحديد موعد الصيانة: $e');
    }
  }

  Future<void> _signOut() async {
    if (!kIsWeb) {
      await FirebaseMessaging.instance.unsubscribeFromTopic('admin_alerts');
    }
    await FirebaseAuth.instance.signOut();
    if (!mounted) {
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم تسجيل الخروج بنجاح')),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'جديد':
        return Colors.green;
      case 'قيد التنفيذ':
        return Colors.orange;
      case 'مكتمل':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(dynamic timestamp) {
    if (timestamp is! Timestamp) {
      return 'غير متوفر';
    }

    final date = timestamp.toDate();
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$year/$month/$day - $hour:$minute';
  }

  Widget _buildRequestsList(String filter) {
    final normalizedFilter = filter.trim();
    final Query<Map<String, dynamic>> streamQuery;
    if (normalizedFilter == 'الكل') {
      streamQuery = FirebaseFirestore.instance
          .collection('requests')
          .orderBy('createdAt', descending: true);
    } else {
      streamQuery = FirebaseFirestore.instance
          .collection('requests')
          .where('status', isEqualTo: normalizedFilter);
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: streamQuery.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('لا توجد طلبات مطابقة حالياً'));
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final docId = docs[index].id;
            final statusValue = data['status'] as String?;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['type']?.toString() ?? 'طلب بدون عنوان',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                data['studentName']?.toString() ??
                                    'اسم غير متوفر',
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.indigo,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'الغرفة: ${data['roomNumber'] ?? 'غير محددة'}',
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDateTime(data['createdAt']),
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _confirmDelete(context, docId),
                          icon: const Icon(Icons.delete),
                          color: Colors.redAccent,
                          tooltip: 'حذف الطلب',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      data['description']?.toString() ?? 'لا يوجد وصف',
                      style: const TextStyle(fontSize: 15),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              statusValue,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            statusValue ?? 'غير معروف',
                            style: TextStyle(
                              color: _getStatusColor(statusValue),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (data['type'] == 'صيانة') ...[
                          OutlinedButton.icon(
                            onPressed: () => _pickScheduledDate(context, docId),
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: const Text('تحديد موعد'),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (statusValue != 'قيد التنفيذ')
                          _statusButton(docId, 'قيد التنفيذ', Colors.orange),
                        if (statusValue != 'مكتمل') ...[
                          const SizedBox(width: 8),
                          _statusButton(docId, 'مكتمل', Colors.blue),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _statusButton(String docId, String status, Color color) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      onPressed: () => _updateStatus(docId, status),
      child: Text(status, style: const TextStyle(fontSize: 12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لوحة إدارة الطلبات'),
          centerTitle: true,
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              onPressed: _showAnnouncementDialog,
              icon: const Icon(Icons.campaign),
              tooltip: 'نشر إعلان',
            ),
            IconButton(
              onPressed: _signOut,
              icon: const Icon(Icons.logout),
              tooltip: 'تسجيل الخروج',
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'الكل'),
              Tab(text: 'جديد'),
              Tab(text: 'قيد التنفيذ'),
              Tab(text: 'مكتمل'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildRequestsList('الكل'),
            _buildRequestsList('جديد'),
            _buildRequestsList('قيد التنفيذ'),
            _buildRequestsList('مكتمل'),
          ],
        ),
      ),
    );
  }
}
