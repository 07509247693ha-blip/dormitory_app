import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;

class FcmService {
  FcmService._();

  static const String _projectId = 'dormitory-management-sys-8e843';
  static const String _serviceAccountPath = 'assets/service_account.json';
  static const List<String> _scopes = <String>[
    'https://www.googleapis.com/auth/firebase.messaging',
  ];

  static auth.AccessToken? _cachedAccessToken;

  static Future<String> _getAccessToken() async {
    final now = DateTime.now().toUtc();
    if (_cachedAccessToken != null &&
        _cachedAccessToken!.expiry.isAfter(now.add(const Duration(minutes: 1)))) {
      return _cachedAccessToken!.data;
    }

    final serviceAccountJson = await rootBundle.loadString(_serviceAccountPath);
    final credentials = auth.ServiceAccountCredentials.fromJson(
      jsonDecode(serviceAccountJson) as Map<String, dynamic>,
    );

    final httpClient = http.Client();
    try {
      final accessCredentials = await auth.obtainAccessCredentialsViaServiceAccount(
        credentials,
        _scopes,
        httpClient,
      );
      _cachedAccessToken = accessCredentials.accessToken;
      return accessCredentials.accessToken.data;
    } finally {
      httpClient.close();
    }
  }

  static Future<void> sendTopicNotification({
    required String topic,
    required String title,
    required String body,
  }) async {
    final accessToken = await _getAccessToken();
    final uri = Uri.parse(
      'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send',
    );

    final response = await http.post(
      uri,
      headers: <String, String>{
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'message': <String, dynamic>{
          'topic': topic,
          'notification': <String, String>{
            'title': title,
            'body': body,
          },
          'data': <String, String>{
            'topic': topic,
            'title': title,
            'body': body,
          },
        },
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'FCM send failed (${response.statusCode}): ${response.body}',
      );
    }
  }
}
