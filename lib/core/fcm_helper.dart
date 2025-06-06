import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

import '../features/models/notification_payload.dart';
import 'callkit_helper.dart';
import 'ui_utils.dart';

@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  UiUtils.showLog(
    'onBackgroundMessage method called - payload - ${message.data.toString()}',
  );
  if (message.data.isNotEmpty) {
    NotificationPayload payload = NotificationPayload.fromJson(message.data);

    if (payload.callAction == CallAction.create ||
        payload.callAction == CallAction.join) {
      UiUtils.showLog('background handler - show callkit incoming');
      CallKitHelper.showCallkitIncoming(payload: payload);
    } else if (payload.callAction == CallAction.end) {
      UiUtils.showLog('background handler - end call');
      CallKitHelper.endAllCalls();
    }
  }
}

class FCMHelper {
  static FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;

  static final String projectId = 'calltest-359ac';
  static final String sendNotificationURL =
      'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';
  static final String verifyFcmTokenURL =
      'https://www.googleapis.com/auth/firebase.messaging';

  static late String fcmToken;

  static Future<void> init() async {
    await firebaseMessaging.requestPermission();
    FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);
    firebaseMessaging.getInitialMessage().then(_onInitialMessage);
    FirebaseMessaging.onMessage.listen(_onMessage);
    fcmToken = await _getFirebaseToken();
  }

  static _onInitialMessage(RemoteMessage? message) {
    UiUtils.showLog(
      'onInitialMessage method called - payload - ${message?.data.toString()}',
    );
    if (message?.data.isNotEmpty ?? false) {
      NotificationPayload payload = NotificationPayload.fromJson(
        message?.data ?? {},
      );

      if (payload.callAction == CallAction.create ||
          payload.callAction == CallAction.join) {
        CallKitHelper.showCallkitIncoming(payload: payload);
      } else if (payload.callAction == CallAction.end) {
        CallKitHelper.endAllCalls();
      }
    }
  }

  static void _onMessage(RemoteMessage message) {
    UiUtils.showLog(
      'onMessage method called - payload - ${message.data.toString()}',
    );
    if (message.data.isNotEmpty) {
      NotificationPayload payload = NotificationPayload.fromJson(message.data);

      if (payload.callAction == CallAction.create ||
          payload.callAction == CallAction.join) {
        CallKitHelper.showCallkitIncoming(payload: payload);
      } else if (payload.callAction == CallAction.end) {
        CallKitHelper.endAllCalls();
      }
    }
  }

  static Future<String> _getFirebaseToken() async {
    String? fcmToken;
    if (Platform.isIOS) {
      String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      if (apnsToken != null) {
        fcmToken = await FirebaseMessaging.instance.getToken();
      } else {
        await Future.delayed(Duration(seconds: 3));
        apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        if (apnsToken != null) {
          fcmToken = await FirebaseMessaging.instance.getToken();
        }
      }
    } else {
      fcmToken = await FirebaseMessaging.instance.getToken();
    }
    return fcmToken ?? '';
  }

  static Future<http.Response?> sendNotification({
    required String fcmToken,
    NotificationPayload? payload,
  }) async {
    final client = await _getAuthClient();

    final data = {
      "message": {
        "token": fcmToken,
        'notification': {},
        "data": payload?.toJson(),
      },
    };

    final response = await client.post(
      Uri.parse(sendNotificationURL),
      body: jsonEncode(data),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      UiUtils.showLog('Notification sent successfully: ${response.body}');
    } else {
      UiUtils.showLog('Failed to send notification: ${response.body}');
    }

    client.close();

    return response;
  }

  static Future<AutoRefreshingAuthClient> _getAuthClient() async {
    final serviceAccountJson = await loadFirebaseConfig();
    final serviceAccountCredentials = ServiceAccountCredentials.fromJson(
      serviceAccountJson,
    );

    final authClient = await clientViaServiceAccount(
      serviceAccountCredentials,
      [verifyFcmTokenURL],
    );

    return authClient;
  }

  static Future<Map<String, dynamic>> loadFirebaseConfig() async {
    final String jsonString = await rootBundle.loadString(
      'assets/firebase_config.json',
    );
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }
}
