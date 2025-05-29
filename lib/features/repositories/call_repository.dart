import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test/features/models/call_log.dart';

import '../../services/base_repository.dart';

class CallRepository extends BaseRepository {
  CollectionReference get _callLog => firestore.collection("callLogs");
  Stream<List> getCalls(String userId) async* {
    final snapshot = await _callLog.get();
    final List customers =
        snapshot.docs
            .where((doc) {
              return doc['caller_id'] == userId || doc['receiver_id'] == userId;
            })
            .map((doc) => CallLogModel.fromFirestore(doc))
            .toList();
    yield customers;
  }

  Future<void> addCall(CallLogModel call) async {
    try {
      _callLog.doc(call.id).set(call.toMap());
    } catch (e) {
      throw "Failed to save user data";
    }
  }
}
