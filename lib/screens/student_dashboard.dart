import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:dormitory_app/notification_service.dart';
import 'package:dormitory_app/screens/create_request_screen.dart';
import 'package:dormitory_app/screens/login_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (!kIsWeb && user.email != 'admin@test.com') {
        FirebaseMessaging.instance.subscribeToTopic('announcements');
      }

      FirebaseFirestore.instance
          .collection('requests')
          .where('uid', isEqualTo: user.uid)
          .snapshots()
          .listen((event) {
            for (var change in event.docChanges) {
              if (change.type == DocumentChangeType.modified) {
                final data = change.doc.data();
                if (data != null) {
                  final newStatus = data['status'];
                  final requestType = data['type'];
                  NotificationService.instance.showNotification(
                    title: 'تحديث في طلب الـ $requestType',
                    body: 'تم تغيير حالة طلبك إلى: $newStatus',
                  );
                }
              }
            }
          });
    }
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

  String _formatScheduledDate(dynamic timestamp) {
    if (timestamp is! Timestamp) {
      return '';
    }

    final date = timestamp.toDate();
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  void _showRequestDetails(BuildContext context, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'تفاصيل طلب ${data['type']}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(),
              const SizedBox(height: 10),
              _detailRow(
                Icons.info_outline,
                'الحالة:',
                data['status'] ?? 'غير معروف',
              ),
              _detailRow(
                Icons.description,
                'التفاصيل:',
                data['description'] ?? 'لا يوجد وصف',
              ),
              _detailRow(
                Icons.calendar_today,
                'تاريخ التقديم:',
                data['createdAt'] != null
                    ? (data['createdAt'] as Timestamp)
                          .toDate()
                          .toString()
                          .split('.')[0]
                    : 'غير متوفر',
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إغلاق'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 5),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsSection() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('announcements')
          .orderBy('createdAt', descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text('لا توجد إعلانات حالياً');
        }

        final docs = snapshot.data!.docs;

        return SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: docs.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final data = docs[index].data();

              return SizedBox(
                width: 260,
                child: Card(
                  color: Colors.orange.shade100,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['title']?.toString() ?? 'إعلان جديد',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: Text(
                            data['body']?.toString() ?? '',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('لوحة تحكم الطالب'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              if (!kIsWeb) {
                await FirebaseMessaging.instance.unsubscribeFromTopic(
                  'announcements',
                );
              }
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) {
                return;
              }
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'بيانات الغرفة',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: const ListTile(
                leading: Icon(Icons.meeting_room, color: Colors.blue, size: 40),
                title: Text(
                  'المبنى: 3 | الطابق: 2',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('الغرفة: 205 | القطاع: ج'),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'إعلانات الإدارة',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildAnnouncementsSection(),
            const SizedBox(height: 30),
            const Text(
              'طلباتي الأخيرة',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('requests')
                    .where(
                      'uid',
                      isEqualTo: FirebaseAuth.instance.currentUser?.uid,
                    )
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    print('Firebase Error: ${snapshot.error}');
                    return Center(
                      child: Text(
                        'حدث خطأ: \n${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('لا توجد طلبات حالياً'));
                  }
                  final docs = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: Icon(
                            data['type'] == 'صيانة'
                                ? Icons.build
                                : Icons.sync_alt,
                            color: _getStatusColor(data['status']),
                          ),
                          title: Text(data['type'] ?? 'طلب عام'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('الحالة: ${data['status']}'),
                              if (data['scheduledDate'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    '📅 موعد الصيانة: ${_formatScheduledDate(data['scheduledDate'])}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () => _showRequestDetails(context, data),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateRequestScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text(
          'إنشاء طلب',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }
}
