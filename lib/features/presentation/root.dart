import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../services/service_locator.dart';
import 'auth/cubit/auth_cubit.dart';
import 'auth/cubit/auth_state.dart';
import 'auth/login_screen.dart';
import 'home/home_screen.dart';

class Root extends StatelessWidget {
  const Root({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      bloc: getIt<AuthCubit>(),
      builder: (context, state) {
        if (state.status == AuthStatus.authenticated) {
       
         
          return HomeScreen(hide:  state.user!.usertype == 'customer'?true:false,);
        } else if (state.status == AuthStatus.unauthenticated ||
            state.status == AuthStatus.error) {
          return const LoginScreen();
        } else {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }
}
