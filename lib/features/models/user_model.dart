import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String username;

  final String? usertype;
  final String fullName;
  final String email;
  final String phoneNumber;
  final bool isOnline;
  final Timestamp lastSeen;
  final Timestamp createdAt;
  final bool isActive;
  final String? fcmToken;
  final List<String> blockedUsers;

  UserModel({
    required this.uid,
    required this.username,
    required this.usertype,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.isActive,
    this.isOnline = false,
    Timestamp? lastSeen,
    Timestamp? createdAt,
    this.fcmToken,
    this.blockedUsers = const [],
  }) : lastSeen = lastSeen ?? Timestamp.now(),
       createdAt = createdAt ?? Timestamp.now();

  UserModel copyWith({
    String? uid,
    String? username,
    String? fullName,
    String? email,
    String? usertype,
    String? phoneNumber,
    bool? isOnline,
    Timestamp? lastSeen,
    Timestamp? createdAt,
    String? fcmToken,
    List<String>? blockedUsers,
    bool? isActive,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      usertype: usertype ?? this.usertype,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
      fcmToken: fcmToken ?? this.fcmToken,
      isActive: isActive ?? this.isActive,
      blockedUsers: blockedUsers ?? this.blockedUsers,
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      username: data["username"] ?? "",
      fullName: data["fullName"] ?? "",
      email: data["email"] ?? "",
      usertype: data["usertype"] ?? "",
      phoneNumber: data["phoneNumber"] ?? "",
      fcmToken: data["fcmToken"],
      lastSeen: data["lastSeen"] ?? Timestamp.now(),
      createdAt: data["createdAt"] ?? Timestamp.now(),
      isActive: data['isActive'] ?? true,
      blockedUsers: List<String>.from(data["blockedUsers"]),
    );
  }
  factory UserModel.fromMap(String id, Map<String, dynamic> data) {
    return UserModel(
      uid: id,
      username: data['username'] ?? '',
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      usertype: data['usertype'],
      phoneNumber: data['phoneNumber'] ?? '',
      isOnline: data['isOnline'] ?? false,
      lastSeen:
          data['lastSeen'] != null
              ? (data['lastSeen'] is Timestamp
                  ? data['lastSeen']
                  : Timestamp.fromMillisecondsSinceEpoch(data['lastSeen']))
              : Timestamp.now(),
      createdAt:
          data['createdAt'] != null
              ? (data['createdAt'] is Timestamp
                  ? data['createdAt']
                  : Timestamp.fromMillisecondsSinceEpoch(data['createdAt']))
              : Timestamp.now(),
      isActive: data['isActive'] ?? true,
      fcmToken: data['fcmToken'],
      blockedUsers:
          data['blockedUsers'] != null
              ? List<String>.from(data['blockedUsers'])
              : [],
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'email': email,
      'fullName': fullName,
      'usertype': usertype,
      'phoneNumber': phoneNumber,
      'isOnline': isOnline,
      'lastSeen': lastSeen,
      'createdAt': createdAt,
      'blockedUsers': blockedUsers,
      'isActive': isActive,
      'fcmToken': '',
    };
  }
}
