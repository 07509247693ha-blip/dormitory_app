import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

const adminEmail = 'admin@test.com';

bool isAdminEmail(String? email) =>
    email?.trim().toLowerCase() == adminEmail.toLowerCase();

Color getStatusColor(String? status) => switch (status) {
  'جديد' => Colors.green,
  'قيد التنفيذ' => Colors.orange,
  'مكتمل' => Colors.blue,
  _ => Colors.grey,
};

String _twoDigits(int value) => value.toString().padLeft(2, '0');

String _formatDate(DateTime date, {bool withTime = false}) {
  final formattedDate =
      '${date.year}/${_twoDigits(date.month)}/${_twoDigits(date.day)}';
  return withTime
      ? '$formattedDate - ${_twoDigits(date.hour)}:${_twoDigits(date.minute)}'
      : formattedDate.replaceAll('/', '-');
}

String formatDateTime(dynamic timestamp) => timestamp is Timestamp
    ? _formatDate(timestamp.toDate(), withTime: true)
    : 'غير متوفر';

String formatDateOnly(dynamic timestamp) =>
    timestamp is Timestamp ? _formatDate(timestamp.toDate()) : '';

String getFloorLevel(String roomNumber) => roomNumber.isEmpty
    ? 'غير محدد'
    : roomNumber.startsWith('1')
    ? 'الأول'
    : roomNumber.startsWith('2')
    ? 'الثاني'
    : roomNumber.startsWith('3')
    ? 'الثالث'
    : 'غير محدد';

Future<void> updateRequestStatus(String docId, String status) =>
    FirebaseFirestore.instance.collection('requests').doc(docId).update({
      'status': status,
    });

Future<void> deleteRequest(String docId) =>
    FirebaseFirestore.instance.collection('requests').doc(docId).delete();

Future<void> scheduleRequestDate(String docId, DateTime date) =>
    FirebaseFirestore.instance.collection('requests').doc(docId).update({
      'scheduledDate': Timestamp.fromDate(date),
    });

Future<void> signOut({String? topic}) async {
  if (!kIsWeb && topic != null) {
    await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
  }
  await FirebaseAuth.instance.signOut();
}

void pushReplacementScreen(BuildContext context, Widget screen) =>
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );

void pushAndClearScreen(BuildContext context, Widget screen) =>
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => screen),
      (_) => false,
    );
