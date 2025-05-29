import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';

import '../../services/base_repository.dart';
import '../models/user_model.dart';

class AuthRepository extends BaseRepository {
  Stream<User?> get authStateChanges => auth.authStateChanges();



  Future<bool> checkPhoneExists(String phoneNumber) async {
    try {
      final formattedPhoneNumber = phoneNumber.replaceAll(
        RegExp(r'\s+'),
        "".trim(),
      );
      final querySnapshot =
          await firestore
              .collection("users")
              .where("phoneNumber", isEqualTo: formattedPhoneNumber)
              .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCredential.user == null) {
        throw "User not found";
      }
      final userData = await getUserData(userCredential.user!.uid);
      return userData;
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }



  Future<void> singOut() async {
    await auth.signOut();
  }

  Future<UserModel> getUserData(String uid) async {
    try {
      final doc = await firestore.collection("users").doc(uid).get();

      if (!doc.exists) {
        throw "User data not found";
      }
      log(doc.id);
      return UserModel.fromFirestore(doc);
    } catch (e) {
      throw "Failed to save user data";
    }
  }
}
