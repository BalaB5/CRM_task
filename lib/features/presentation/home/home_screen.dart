import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:get_it/get_it.dart';
import 'package:test/core/extensions.dart';
import 'package:test/features/presentation/call/call_list.dart';
import 'package:uuid/uuid.dart';
import '../../../core/app_router.dart';
import '../../../core/fcm_helper.dart';
import '../../../core/ui_utils.dart';
import '../../../services/service_locator.dart';
import '../../models/call_log.dart';
import '../../models/chat_room_model.dart';
import '../../models/notification_payload.dart';
import '../../models/user_model.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/call_repository.dart';
import '../auth/cubit/auth_cubit.dart';
import '../auth/login_screen.dart';
import '../widgets/custom_textfield.dart';
import 'add_customer.dart';
import '../chat/chat_message_screen.dart';
import '../chat/chat_list.dart';
import '../call/audio_call_page.dart';
import 'bloc/customer_bloc.dart';

class HomeScreen extends StatefulWidget {
  final bool hide;
  const HomeScreen({super.key, this.hide = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();

  late final User _auth;
  late final UserModel _currentUser;
  @override
  void initState() {
    super.initState();
    _auth = GetIt.instance<AuthRepository>().currentUser!;
    getdat();
    context.read<CustomerBloc>().add(LoadCustomers());
    WidgetsBinding.instance.addObserver(this);
    checkForPendingCall();
    registerCallActionListeners();
  }

  Future<void> checkForPendingCall() async {
    var calls = await FlutterCallkitIncoming.activeCalls();
    if (calls is List && calls.isNotEmpty) {
      UiUtils.showLog('call.first: ${calls.first.toString()}');

      Map<String, dynamic> temp = calls.first['extra'].cast<String, dynamic>();
      NotificationPayload data = NotificationPayload.fromJson(temp);
      UiUtils.showLog('check here: ${data.toJson()}');
    }
  }

  getdat() async {
    final userRef = FirebaseFirestore.instance
        .collection("users")
        .doc(_auth.uid);
    var fcmToken = FCMHelper.fcmToken;
    await userRef.update({'fcmToken': fcmToken});
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    final customers =
        snapshot.docs
            .where((doc) {
              return doc['email'] == _auth.email;
            })
            .map((doc) => UserModel.fromMap(doc.id, doc.data()))
            .toList();
    _currentUser = customers[0];
  }

  void _showCustomerDialog({UserModel? customer}) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(customer == null ? 'Add Customer' : 'Edit Customer'),
            content: AddUserScreen(customer: customer),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  void showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Logout',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
              fontSize: 20,
            ),
          ),
          content: const Text(
            'Are you sure you want to logout ',
            style: TextStyle(fontSize: 16),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();

                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return const Center(child: CircularProgressIndicator());
                  },
                );

                try {
                  await getIt<AuthCubit>().signOut();

                  final navigator =
                      getIt<AppRouter>().navigatorKey.currentState;
                  if (navigator != null) {
                    navigator.pop();
                    navigator.pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                      (route) => false,
                    );
                  }
                } catch (e) {
                  final navigator =
                      getIt<AppRouter>().navigatorKey.currentState;
                  if (navigator != null) {
                    navigator.pop();
                    ScaffoldMessenger.of(navigator.context).showSnackBar(
                      SnackBar(
                        content: Text('Logout failed: ${e.toString()}'),
                        backgroundColor: Theme.of(context).primaryColor,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColorDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> registerCallActionListeners({Function? callback}) async {
    try {
      FlutterCallkitIncoming.onEvent.listen((event) async {
        UiUtils.showLog(
          'FlutterCallkitIncoming Event: ${event?.event} body: ${event?.body}',
        );
        switch (event!.event) {
          case Event.actionCallIncoming:
            break;
          case Event.actionCallStart:
            break;
          case Event.actionCallAccept:
            Map<String, dynamic> temp =
                event.body['extra'].cast<String, dynamic>();
            NotificationPayload data = NotificationPayload.fromJson(temp);
            UiUtils.showLog('check here: ${data.toJson()}');
            if (mounted) {
              if (data.callType == CallType.audio) {
                getIt<AppRouter>().navigatorKey.currentState!.push(
                  MaterialPageRoute(
                    builder: (context) => AudioCallPage(data: data),
                  ),
                );
              }
            }
            break;
          case Event.actionCallDecline:
            break;
          case Event.actionCallEnded:
            break;
          case Event.actionCallTimeout:
            break;
          case Event.actionCallCallback:
            break;
          case Event.actionCallToggleHold:
            break;
          case Event.actionCallToggleMute:
            break;
          case Event.actionCallToggleDmtf:
            break;
          case Event.actionCallToggleGroup:
            break;
          case Event.actionCallToggleAudioSession:
            break;
          case Event.actionDidUpdateDevicePushTokenVoip:
            break;
          case Event.actionCallCustom:
            break;
        }
        if (callback != null) {
          callback(event.toString());
        }
      });
    } on Exception {
      UiUtils.showLog('call event exception');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Customer Management',
          style: TextStyle(color: Colors.white),
        ),
        foregroundColor: Colors.white,
        iconTheme: IconThemeData(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          InkWell(
            onTap: () {
              getIt<AppRouter>().navigatorKey.currentState!.push(
                MaterialPageRoute(builder: (context) => const ChatListScreen()),
              );
            },
            child: const Padding(
              padding: EdgeInsets.only(right: 16.0, left: 16.0),
              child: Icon(
                Icons.add_alert_rounded,
                size: 25,
                color: Colors.white,
              ),
            ),
          ),
          InkWell(
            onTap: () {
              getIt<AppRouter>().navigatorKey.currentState!.push(
                MaterialPageRoute(builder: (context) => const CallListScreen()),
              );
            },
            child: const Padding(
              padding: EdgeInsets.only(right: 16.0, left: 16.0),
              child: Icon(Icons.phone, size: 25, color: Colors.white),
            ),
          ),
          InkWell(
            onTap: showLogoutDialog,
            child: const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Icon(Icons.logout, size: 25, color: Colors.white),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            if (!widget.hide)
              CustomTextField(
                hintText: 'Search Customers',
                controller: _searchController,
                onChanged: (query) {
                  context.read<CustomerBloc>().add(SearchCustomer(query));
                },
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context.read<CustomerBloc>().add(LoadCustomers());
                  },
                ),
              ),

            10.0.spaceHeight,
            Expanded(
              child: BlocBuilder<CustomerBloc, CustomerState>(
                builder: (context, state) {
                  if (state is CustomerLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is CustomerLoaded) {
                    if (state.customers.isEmpty) {
                      return const Center(child: Text('No customers found.'));
                    }
                    return ListView.builder(
                      itemCount: state.customers.length,

                      itemBuilder: (_, index) {
                        final c = state.customers[index];
                        return Container(
                          margin: EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).primaryColor.withAlpha((0.08 * 255).round()),
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                            border: Border(
                              left: BorderSide(
                                color:
                                    c.isActive ? Colors.green : Colors.orange,
                                width: 10.0,
                              ),
                            ),
                          ),
                          child: ListTile(
                            title: Text(
                              '${c.fullName[0].toUpperCase()}${c.fullName.substring(1)}',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text('${c.email}\n${c.phoneNumber}'),
                            trailing: Wrap(
                              spacing: 1,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.message,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    getIt<AppRouter>().push(
                                      ChatMessageScreen(
                                        receiverId: c.uid,
                                        receiverName: c.username,
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  onPressed: () async {
                                    final payload = NotificationPayload(
                                      userId: _currentUser.uid,
                                      name: _currentUser.fullName,
                                      username: _currentUser.username,

                                      fcmToken: _currentUser.fcmToken,
                                      callAction: CallAction.join,
                                      callType: CallType.audio,
                                      notificationId: const Uuid().v1(),
                                      webrtcRoomId: const Uuid().v1(),
                                    );
                                    final response =
                                        await FCMHelper.sendNotification(
                                          fcmToken: c.fcmToken ?? '',
                                          payload: payload,
                                        );
                                    if (response?.statusCode == 200) {
                                      payload.fcmToken = c.fcmToken;
                                      payload.callAction = CallAction.create;
                                      payload.userId = c.uid;
                                      payload.name = c.username;
                                      payload.username = c.username;

                                      payload.fcmToken = c.fcmToken;
                                      if (context.mounted) {
                                        CallLogModel call = CallLogModel(
                                          id: Timestamp.now().toString(),
                                          callerID: _currentUser.uid,
                                          receiverID: c.uid,
                                          callerName: _currentUser.fullName,
                                          receiverName: c.fullName,
                                          time: DateTime.now(),
                                        );
                                        getIt<CallRepository>().addCall(call);
                                        getIt<AppRouter>()
                                            .navigatorKey
                                            .currentState!
                                            .push(
                                              MaterialPageRoute(
                                                builder:
                                                    (context) => AudioCallPage(
                                                      data: payload,
                                                    ),
                                              ),
                                            );
                                      }
                                    } else {
                                      'User not available please try later'
                                          .showSnackBar;
                                    }
                                  },
                                  splashRadius: 18,
                                  icon: const Icon(
                                    CupertinoIcons.phone_solid,
                                    color: Colors.red,
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  position: PopupMenuPosition.under,
                                  popUpAnimationStyle: AnimationStyle(
                                    curve: Curves.easeInOutQuad,
                                  ),
                                  color: Colors.white,
                                  onSelected: (value) {
                                    if (value == 'delete') {
                                      'Delete Clicked'.showSnackBar;
                                    }
                                  },
                                  itemBuilder: (BuildContext context) {
                                    return [
                                      PopupMenuItem(
                                        onTap:
                                            () => _showCustomerDialog(
                                              customer: c,
                                            ),
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 7,
                                              ),
                                              child: Icon(
                                                Icons.edit_note,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            Text('Edit', style: TextStyle()),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        onTap: () {
                                          context.read<CustomerBloc>().add(
                                            DeleteCustomer(
                                              email: c.email,
                                              customerId: c.uid,
                                            ),
                                          );
                                        },
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 7,
                                              ),
                                              child: Icon(
                                                Icons.delete_outlined,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            Text('Delete', style: TextStyle()),
                                          ],
                                        ),
                                      ),
                                    ];
                                  },
                                  icon: Icon(Icons.more_vert),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  } else if (state is CustomerError) {
                    return Center(child: Text(state.message));
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton:
          !widget.hide
              ? FloatingActionButton(
                onPressed: () => _showCustomerDialog(),
                child: const Icon(Icons.add),
              )
              : Container(),
    );
  }
}
