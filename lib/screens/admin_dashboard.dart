import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dormitory_app/services/fcm_service.dart';
import 'package:dormitory_app/screens/login_screen.dart';
import 'package:dormitory_app/utils/helpers.dart';
import 'package:dormitory_app/widgets/custom_widgets.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _announcementTitleController = TextEditingController();
  final _announcementBodyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      FirebaseMessaging.instance.subscribeToTopic('admin_alerts');
    }
  }

  Future<void> _runRequestAction(
    Future<void> Function() action,
    String errorMessage,
  ) async {
    try {
      await action();
    } catch (e) {
      debugPrint('$errorMessage: $e');
    }
  }

  Future<void> _updateStatus(String docId, String status) => _runRequestAction(
    () => updateRequestStatus(docId, status),
    'خطأ في التحديث',
  );

  Future<void> _deleteRequest(String docId) =>
      _runRequestAction(() => deleteRequest(docId), 'خطأ في الحذف');

  Future<void> _pickScheduledDate(String docId) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (selectedDate == null) return;
    await _runRequestAction(
      () => scheduleRequestDate(docId, selectedDate),
      'خطأ في تحديد موعد الصيانة',
    );
  }

  Future<void> _confirmDelete(String docId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
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
      ),
    );

    if (shouldDelete == true) {
      await _deleteRequest(docId);
    }
  }

  Future<void> _publishAnnouncement() async {
    final title = _announcementTitleController.text.trim();
    final body = _announcementBodyController.text.trim();
    if (title.isEmpty || body.isEmpty) return;

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
      debugPrint('خطأ في نشر الإعلان: $e');
    }
  }

  Future<void> _showAnnouncementDialog() async {
    _announcementTitleController.clear();
    _announcementBodyController.clear();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('نشر إعلان جديد'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              appTextField(
                controller: _announcementTitleController,
                labelText: 'عنوان الإعلان',
                icon: Icons.title,
              ),
              const SizedBox(height: 12),
              appTextField(
                controller: _announcementBodyController,
                labelText: 'نص الإعلان',
                icon: Icons.campaign,
                maxLines: 4,
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
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('نشر'),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    await signOut(topic: 'admin_alerts');
    if (!mounted) return;
    pushAndClearScreen(context, const LoginScreen());
    showAppSnackBar(context, 'تم تسجيل الخروج بنجاح');
  }

  Query<Map<String, dynamic>> _requestQuery(String filter) {
    final normalizedFilter = filter.trim();
    return normalizedFilter == 'الكل'
        ? FirebaseFirestore.instance
              .collection('requests')
              .orderBy('createdAt', descending: true)
        : FirebaseFirestore.instance
              .collection('requests')
              .where('status', isEqualTo: normalizedFilter);
  }

  Widget _statusButton(String docId, String status, Color color) =>
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        onPressed: () => _updateStatus(docId, status),
        child: Text(status, style: const TextStyle(fontSize: 12)),
      );

  Widget _buildRequestCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
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
                        '${data['type'] ?? 'طلب بدون عنوان'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${data['studentName'] ?? 'اسم غير متوفر'}',
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
                        formatDateTime(data['createdAt']),
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _confirmDelete(doc.id),
                  icon: const Icon(Icons.delete),
                  color: Colors.redAccent,
                  tooltip: 'حذف الطلب',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${data['description'] ?? 'لا يوجد وصف'}',
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
                    color: getStatusColor(statusValue).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    statusValue ?? 'غير معروف',
                    style: TextStyle(
                      color: getStatusColor(statusValue),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                if (data['type'] == 'صيانة') ...[
                  OutlinedButton.icon(
                    onPressed: () => _pickScheduledDate(doc.id),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: const Text('تحديد موعد'),
                  ),
                  const SizedBox(width: 8),
                ],
                if (statusValue != 'قيد التنفيذ')
                  _statusButton(doc.id, 'قيد التنفيذ', Colors.orange),
                if (statusValue != 'مكتمل') ...[
                  const SizedBox(width: 8),
                  _statusButton(doc.id, 'مكتمل', Colors.blue),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsList(String filter) =>
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _requestQuery(filter).snapshots(),
        builder: (_, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('لا توجد طلبات مطابقة حالياً'));
          }
          return ListView(
            padding: const EdgeInsets.all(12),
            children: snapshot.data!.docs.map(_buildRequestCard).toList(),
          );
        },
      );

  PreferredSizeWidget _buildAppBar() => AppBar(
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
  );

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 4,
    child: Scaffold(
      appBar: _buildAppBar(),
      body: TabBarView(
        children: [
          'الكل',
          'جديد',
          'قيد التنفيذ',
          'مكتمل',
        ].map((filter) => _buildRequestsList(filter)).toList(),
      ),
    ),
  );
}
