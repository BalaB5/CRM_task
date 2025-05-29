import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/presentation/root.dart';
import 'core/app_theme.dart';
import 'core/app_router.dart';
import 'core/fcm_helper.dart';
import 'services/app_life_cycle_observer.dart';
import 'services/service_locator.dart';
import 'features/presentation/home/bloc/customer_bloc.dart';
import 'features/repositories/chat_repository.dart';
import 'features/repositories/customer_repository.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FCMHelper.init();
  await setupServiceLocator();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  AppLifeCycleObserver? _appLifeCycleObserver;

  @override
  void initState() {
    super.initState();
    _initializeAppLifeCycleObserver();
    WidgetsBinding.instance.addObserver(this);
  }

  void _initializeAppLifeCycleObserver() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        if (_appLifeCycleObserver != null) {
          WidgetsBinding.instance.removeObserver(_appLifeCycleObserver!);
        }

        _appLifeCycleObserver = AppLifeCycleObserver(
          userId: user.uid,
          chatRepository: getIt<ChatRepository>(),
        );
        WidgetsBinding.instance.addObserver(_appLifeCycleObserver!);
      } else {
        if (_appLifeCycleObserver != null) {
          WidgetsBinding.instance.removeObserver(_appLifeCycleObserver!);
        }
        _appLifeCycleObserver = null;
      }
    });
  }

  @override
  void dispose() {
    if (_appLifeCycleObserver != null) {
      WidgetsBinding.instance.removeObserver(_appLifeCycleObserver!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create:
              (_) => CustomerBloc(
                customerRepository: getIt<CustomerRepository>(),
                firestore: FirebaseFirestore.instance,
              ),
        ),
      ],
      child: MaterialApp(
        title: 'CRM_chat',
        navigatorKey: getIt<AppRouter>().navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: Root(),
      ),
    );
  }
}
