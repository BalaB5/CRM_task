import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../core/app_router.dart';
import '../features/presentation/auth/cubit/auth_cubit.dart';
import '../features/presentation/call/bloc/signaling_bloc.dart';
import '../features/presentation/chat/cubit/chat_cubit.dart';
import '../features/repositories/auth_repository.dart';
import '../features/repositories/call_repository.dart';
import '../features/repositories/chat_repository.dart';
import '../features/repositories/customer_repository.dart';
import '../firebase_options.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  getIt.registerLazySingleton(() => AppRouter());
  getIt.registerLazySingleton<FirebaseFirestore>(
    () => FirebaseFirestore.instance,
  );
 getIt. registerLazySingleton(() => SignalingBloc());
  
  getIt.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  getIt.registerLazySingleton(() => AuthRepository());
  getIt.registerLazySingleton(() => CallRepository());
  getIt.registerLazySingleton(() => CustomerRepository());
  getIt.registerLazySingleton(() => ChatRepository());
  getIt.registerLazySingleton(
    () => AuthCubit(authRepository: AuthRepository()),
  );
  getIt.registerFactory(
    () => ChatCubit(
      chatRepository: ChatRepository(),
      currentUserId: getIt<FirebaseAuth>().currentUser!.uid,
    ),
  );
}
