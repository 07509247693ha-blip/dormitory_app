import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dormitory_app/services/notification_service.dart';
import 'package:dormitory_app/screens/create_request_screen.dart';
import 'package:dormitory_app/screens/login_screen.dart';
import 'package:dormitory_app/utils/helpers.dart';
import 'package:dormitory_app/widgets/custom_widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}
//initState ملاحظة اي تغير يجريه المدير على حالة الطلب وارسال اشعار
class _StudentDashboardState extends State<StudentDashboard> {
  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !kIsWeb && !isAdminEmail(user.email)) {
      FirebaseMessaging.instance.subscribeToTopic('announcements');
    }
    _listenForRequestUpdates();
  }

  void _listenForRequestUpdates() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    FirebaseFirestore.instance
        .collection('requests')
        .where('uid', isEqualTo: user.uid)
        .snapshots()
        .listen((event) {
          for (final change in event.docChanges) {
            if (change.type != DocumentChangeType.modified) continue;
            final data = change.doc.data();
            if (data == null) continue;
            NotificationService.instance.showNotification(
              title: 'تحديث في طلب الـ ${data['type']}',
              body: 'تم تغيير حالة طلبك إلى: ${data['status']}',
            );
          }
        });
  }

  Future<void> _signOut() async {
    await signOut(topic: 'announcements');
    if (mounted) pushAndClearScreen(context, const LoginScreen());
  }

  void _showRequestDetails(Map<String, dynamic> data) => showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => Padding(
      padding: const EdgeInsets.all(20),
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
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          const SizedBox(height: 10),
          _detailRow(
            Icons.info_outline,
            'الحالة:',
            '${data['status'] ?? 'غير معروف'}',
          ),
          _detailRow(
            Icons.description,
            'التفاصيل:',
            '${data['description'] ?? 'لا يوجد وصف'}',
          ),
          _detailRow(
            Icons.calendar_today,
            'تاريخ التقديم:',
            data['createdAt'] != null
                ? (data['createdAt'] as Timestamp)
                      .toDate()
                      .toString()
                      .split('.')
                      .first
                : 'غير متوفر',
          ),
          const SizedBox(height: 30),
          appPrimaryButton(
            label: 'إغلاق',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    ),
  );

  Widget _detailRow(IconData icon, String title, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
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

  Widget _buildAnnouncementsSection() =>
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('announcements')
            .orderBy('createdAt', descending: true)
            .limit(3)// استدعاء فقط اخر 3 اعلانات
            .snapshots(),
        builder: (_, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Text('لا توجد إعلانات حالياً');
          }
//لوحة الاعلانات 
          return SizedBox(
            height: 170,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: snapshot.data!.docs.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, index) {
                final data = snapshot.data!.docs[index].data();
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
                            '${data['title'] ?? 'إعلان جديد'}',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: Text(
                              '${data['body'] ?? ''}',
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

  Widget _buildRequestsSection() => Expanded(
    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('requests')//(استعلام مشروط Query) في قاعدة البيانات يجلب فقط الطلبات التي يتطابق فيها uid الطلب مع uid الهاتف الحالي
          .where('uid', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (_, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          debugPrint('Firebase Error: ${snapshot.error}');
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

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (_, index) {
            final data = snapshot.data!.docs[index].data();
            final scheduledDate = formatDateOnly(data['scheduledDate']);
            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading: Icon(
                  data['type'] == 'صيانة' ? Icons.build : Icons.sync_alt,
                  color: getStatusColor(data['status'] as String?),
                ),
                title: Text('${data['type'] ?? 'طلب عام'}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('الحالة: ${data['status']}'),
                    if (scheduledDate.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '📅 موعد الصيانة: $scheduledDate',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showRequestDetails(data),
              ),
            );
          },
        );
      },
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.grey[100],
    appBar: AppBar(
      title: const Text('لوحة تحكم الطالب'),
      centerTitle: true,
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      actions: [
        IconButton(icon: const Icon(Icons.logout), onPressed: _signOut),
      ],
    ),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sectionTitle('بيانات الغرفة'),
          const SizedBox(height: 10),
StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser?.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Card(
                  child: ListTile(title: Text('جاري تحميل بيانات الغرفة...')),
                );
              }

              // سحب البيانات الفعلية للطالب من قاعدة البيانات
              final userData = snapshot.data!.data()!;
              final building = userData['buildingNumber'] ?? '-';
              final floor = userData['floorLevel'] ?? '-';
              final room = userData['roomNumber'] ?? '-';
              final sector = userData['sector'] ?? '-';
              final complex = userData['complexName'] ?? 'مجمع غير محدد';

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(Icons.meeting_room, color: Colors.blue, size: 40),
                  title: Text(
                    'المبنى: $building | الطابق: $floor',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text('الغرفة: $room | القطاع: $sector\n$complex'),
                  ),
                  isThreeLine: true, // للسماح بعرض اسم المجمع في سطر جديد
                ),
              );
            },
          ),
          const SizedBox(height: 30),
          sectionTitle('إعلانات الإدارة'),
          const SizedBox(height: 10),
          _buildAnnouncementsSection(),
          const SizedBox(height: 30),
          sectionTitle('طلباتي الأخيرة'),
          const SizedBox(height: 10),
          _buildRequestsSection(),
        ],
      ),
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CreateRequestScreen()),
      ),
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
