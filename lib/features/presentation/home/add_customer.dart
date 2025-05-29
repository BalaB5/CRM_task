import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test/core/extensions.dart';

import '../../../core/app_router.dart';
import '../../../core/ui_utils.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../../../services/service_locator.dart';
import '../../models/user_model.dart';
import 'bloc/customer_bloc.dart';
import 'home_screen.dart';
import '../auth/cubit/auth_cubit.dart';
import '../auth/cubit/auth_state.dart';

class AddUserScreen extends StatefulWidget {
  final UserModel? customer;
  const AddUserScreen({super.key, this.customer});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isActive = true;
  String? uid;
  bool _isPasswordVisible = false;

  final _nameFocus = FocusNode();
  final _usernameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _phoneFocus = FocusNode();

  @override
  void initState() {
    if (widget.customer != null) {
      UserModel data = widget.customer!;
      uid = data.uid;
      emailController.text = data.email;
      nameController.text = data.fullName;
      usernameController.text = data.username;
      phoneController.text = data.phoneNumber;
      isActive = data.isActive;
    }
    super.initState();
  }

  @override
  void dispose() {
    emailController.dispose();
    nameController.dispose();
    usernameController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    _nameFocus.dispose();
    _usernameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return "Please enter your full name";
    }
    return null;
  }

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return "Please enter your username";
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email address';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address (e.g., example@email.com)';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (widget.customer == null) {
      return null;
    }
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }

    final phoneRegex = RegExp(r'^[\d\s-]{10,}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Please enter a valid phone number (e.g., 1234567890)';
    }
    return null;
  }

  Future<void> handleAddUser() async {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState?.validate() ?? false) {
      try {
        if (widget.customer == null) {
          context.read<CustomerBloc>().add(
            AddCustomer(
              fullName: nameController.text,
              username: usernameController.text,
              email: emailController.text,
              phoneNumber: phoneController.text,
              password: passwordController.text,
            ),
          );
        } else {
          context.read<CustomerBloc>().add(
            UpdateCustomer(
              id: uid ?? '',
              fullName: nameController.text,

              phoneNumber: phoneController.text,
              isActive: isActive,
            ),
          );
        }
      } catch (e) {
        e.toString().showSnackBar;
      }
    } else {}
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      bloc: getIt<AuthCubit>(),
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          getIt<AppRouter>().pushAndRemoveUntil(const HomeScreen());
        } else if (state.status == AuthStatus.error && state.error != null) {
          UiUtils.showSnackBar(context, message: state.error!);
        }
      },
      builder: (context, state) {
        return SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 0.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomTextField(
                    controller: nameController,
                    focusNode: _nameFocus,
                    hintText: "Full Name",
                    validator: _validateName,
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  if (widget.customer == null)
                    Column(
                      children: [
                        10.0.spaceHeight,
                        CustomTextField(
                          controller: usernameController,
                          hintText: "Username",
                          focusNode: _usernameFocus,
                          validator: _validateUsername,
                          prefixIcon: const Icon(Icons.alternate_email),
                        ),
                          10.0.spaceHeight,
                        CustomTextField(
                          controller: emailController,
                          hintText: "Email",
                          focusNode: _emailFocus,
                          validator: _validateEmail,
                          prefixIcon: const Icon(Icons.email_outlined),
                        ),
                      ],
                    ),
                    10.0.spaceHeight,
                  CustomTextField(
                    controller: phoneController,
                    focusNode: _phoneFocus,
                    validator: _validatePhone,
                    hintText: "Phone Number",
                    prefixIcon: const Icon(Icons.phone_outlined),
                  ),
                  if (widget.customer != null)
                    Column(
                      children: [
                           10.0.spaceHeight,
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Active"),
                            CupertinoSwitch(
                              value: isActive,
                              onChanged: (value) {
                                setState(() {
                                  isActive = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  if (widget.customer == null)
                    Column(
                      children: [
                           10.0.spaceHeight,
                        CustomTextField(
                          controller: passwordController,
                          obscureText: !_isPasswordVisible,
                          hintText: "Password",
                          focusNode: _passwordFocus,
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          ),
                          validator: _validatePassword,
                          prefixIcon: const Icon(Icons.lock_outline),
                        ),
                      ],
                    ),
                    10.0.spaceHeight,
                  CustomButton(
                    onPressed: handleAddUser,
                    text: (widget.customer == null) ? "Add" : "Update",
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
