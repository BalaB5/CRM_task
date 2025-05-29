import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../core/fcm_helper.dart';
import '../../services/base_repository.dart';
import '../models/user_model.dart';

class CustomerRepository extends BaseRepository {
  String get currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<UserModel> createuser({
    required String fullName,
    required String username,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    final emailExists = await checkEmailExists(email);
    if (emailExists) {
      throw "An account with the same email already exists";
    }

    // Initialize a secondary Firebase app
    final FirebaseApp secondaryApp = await Firebase.initializeApp(
      name: 'SecondaryUserCreation',
      options: Firebase.app().options,
    );

    try {
      final UserCredential userCredential = await FirebaseAuth.instanceFor(
        app: secondaryApp,
      ).createUserWithEmailAndPassword(email: email, password: password);

      if (userCredential.user == null) {
        throw "Failed to create user";
      }

      final user = UserModel(
        uid: userCredential.user!.uid,
        username: username,
        fullName: fullName,
        usertype: "customer",
        isActive: true,
        email: email,
        phoneNumber: phoneNumber,
      );

      await saveUserData(user);

      return user;
    } catch (e) {
      log(e.toString());
      rethrow;
    } finally {
      await secondaryApp.delete();
    }
  }

  Future<bool> checkEmailExists(String email) async {
    try {
      final methods = await auth.fetchSignInMethodsForEmail(email);
      return methods.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> saveUserData(UserModel user) async {
    try {
      firestore.collection("users").doc(user.uid).set(user.toMap());
    } catch (e) {
      throw "Failed to save user data";
    }
  }

  Future<void> updateFCM(String currentUserId) async {
    final userRef = firestore.collection("users").doc(currentUserId);
    await userRef.update({'fcmToken': FCMHelper.fcmToken});
  }

  Future<List<Map<String, dynamic>>> getRegisteredCustomers() async {
    try {
      final usersSnapshot = await firestore.collection('users').get();
      final registeredUsers =
          usersSnapshot.docs
              .map((doc) => UserModel.fromFirestore(doc))
              .toList();

      final phoneNumbers =
          registeredUsers
              .where((contact) => contact.phoneNumber.isNotEmpty)
              .map(
                (contact) => {
                  'name': contact.fullName,
                  'phoneNumber': contact.phoneNumber,
                },
              )
              .toList();

      final matchedCustomers =
          phoneNumbers.map((contact) {
            String phoneNumber = contact["phoneNumber"].toString();

            final registeredUser = registeredUsers.firstWhere(
              (user) => user.phoneNumber == phoneNumber,
            );

            return {
              'id': registeredUser.uid,
              'name': contact['name'],
              'phoneNumber': contact['phoneNumber'],
            };
          }).toList();

      return matchedCustomers;
    } catch (e) {
      return [];
    }
  }
}
