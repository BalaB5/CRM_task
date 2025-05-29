class NotificationPayload {
  String? userId;
  String? name;
  String? username;

  String? fcmToken;
  CallType? callType;
  CallAction? callAction;
  String? notificationId;
  String? webrtcRoomId;

  NotificationPayload({
    this.userId,
    this.name,
    this.username,

    this.fcmToken,
    this.callType,
    this.callAction,
    this.notificationId,
    this.webrtcRoomId,
  });

  factory NotificationPayload.fromJson(Map<String, dynamic> json) {
    return NotificationPayload(
      userId: json['userId'] as String?,
      name: json['name'] as String?,
      username: json['username'] as String?,
      fcmToken: json['fcmToken'] as String?,
      callType: _decodeCallType(json['callType']),
      callAction: _decodeCallAction(json['callAction']),
      notificationId: json['notificationId'] as String?,
      webrtcRoomId: json['webrtcRoomId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (userId != null) 'userId': userId,
      if (name != null) 'name': name,
      if (username != null) 'username': username,
      if (fcmToken != null) 'fcmToken': fcmToken,
      if (callType != null) 'callType': _encodeCallType(callType!),
      if (callAction != null) 'callAction': _encodeCallAction(callAction!),
      if (notificationId != null) 'notificationId': notificationId,
      if (webrtcRoomId != null) 'webrtcRoomId': webrtcRoomId,
    };
  }

  static CallType? _decodeCallType(dynamic value) {
    switch (value) {
      case 'audio':
        return CallType.audio;

      default:
        return null;
    }
  }

  static String? _encodeCallType(CallType value) {
    switch (value) {
      case CallType.audio:
        return 'audio';
    }
  }

  static CallAction? _decodeCallAction(dynamic value) {
    switch (value) {
      case 'create':
        return CallAction.create;
      case 'join':
        return CallAction.join;
      case 'end':
        return CallAction.end;
      default:
        return null;
    }
  }

  static String? _encodeCallAction(CallAction value) {
    switch (value) {
      case CallAction.create:
        return 'create';
      case CallAction.join:
        return 'join';
      case CallAction.end:
        return 'end';
    }
  }
}

enum CallType { audio }

enum CallAction { create, join, end }
