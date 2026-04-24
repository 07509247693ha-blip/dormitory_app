import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;

class FcmService {
  FcmService._();

  static const _serviceAccountPath = 'assets/service_account.json';
  static const _scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
  static final _uri = Uri.parse(
    'https://fcm.googleapis.com/v1/projects/dormitory-management-sys-8e843/messages:send',
  );

  static auth.AccessToken? _cachedAccessToken;

  static Future<String> _getAccessToken() async {
    final token = _cachedAccessToken;
    if (token != null &&
        token.expiry.isAfter(
          DateTime.now().toUtc().add(const Duration(minutes: 1)),
        )) {
      return token.data;
    }

    final credentials = auth.ServiceAccountCredentials.fromJson(
      jsonDecode(await rootBundle.loadString(_serviceAccountPath))
          as Map<String, dynamic>,
    );
    final client = http.Client();

    try {
      final access = await auth.obtainAccessCredentialsViaServiceAccount(
        credentials,
        _scopes,
        client,
      );
      _cachedAccessToken = access.accessToken;
      return access.accessToken.data;
    } finally {
      client.close();
    }
  }

  static Future<void> sendTopicNotification({
    required String topic,
    required String title,
    required String body,
  }) async {
    final response = await http.post(
      _uri,
      headers: {
        'Authorization': 'Bearer ${await _getAccessToken()}',
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'message': {
          'topic': topic,
          'notification': {'title': title, 'body': body},
          'data': {'topic': topic, 'title': title, 'body': body},
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
