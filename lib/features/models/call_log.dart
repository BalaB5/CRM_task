import 'package:cloud_firestore/cloud_firestore.dart';

class CallLogModel {
  final String id;
  final String receiverID;
  final String callerID;
  final String receiverName;
  final String callerName;
  final DateTime? time;

  CallLogModel({
    required this.receiverID,
    required this.callerID,
    required this.receiverName,
    required this.callerName,
    required this.id,
    this.time,
  });

factory CallLogModel.fromFirestore(DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>;
  return CallLogModel(
    id: doc.id,
    receiverID: data['receiver_id'] ?? '',
    callerID: data['caller_id'] ?? '',
    receiverName: data['receiver_name'] ?? '',
    callerName: data['caller_name'] ?? '',
    time: (data['calltime'] as Timestamp?)?.toDate(), // Convert Timestamp to DateTime
  );
}


  Map<String, dynamic> toMap() {
    return {
      'receiver_id': receiverID,
      'caller_id': callerID,
      'receiver_name': receiverName,
      'caller_name': callerName,
      'calltime': time,
    };
  }
}
