import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:test/features/models/call_log.dart';

import '../../../services/service_locator.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/call_repository.dart';

class CallListScreen extends StatefulWidget {
  const CallListScreen({super.key});

  @override
  State<CallListScreen> createState() => _CallListScreenState();
}

class _CallListScreenState extends State<CallListScreen> {
  late final CallRepository _callRepository;
  late final String _currentUserId;

  @override
  void initState() {
    _callRepository = getIt<CallRepository>();
    var currentUser2 = getIt<AuthRepository>().currentUser;
    _currentUserId = currentUser2?.uid ?? "";

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Padding(
          padding: EdgeInsets.only(left: 16.0),
          child: Text("Call Logs"),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        foregroundColor: Colors.white,
        iconTheme: IconThemeData(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: StreamBuilder(
        stream: _callRepository.getCalls(_currentUserId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("error:${snapshot.error}"));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final calls = snapshot.data!;
          if (calls.isEmpty) {
            return const Center(child: Text("No recent chats"));
          }
          return ListView.builder(
            itemCount: calls.length,
            itemBuilder: (context, index) {
              CallLogModel call = calls[index];

              var name =
                  _currentUserId == call.receiverID
                      ? call.callerName
                      : call.receiverName;
              return Container(
                margin: EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).primaryColor.withAlpha((0.08 * 255).round()),
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColorDark,
                    foregroundImage: NetworkImage(
                      "https://ui-avatars.com/api/?name=${name}&background=${Theme.of(context).primaryColorDark}&color=fff",
                    ),
                    child: Text(
                      (name)[0].toUpperCase(),
                      style: TextStyle(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  title: Text(name),

                  subtitle: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                        _currentUserId != call.receiverID
                            ? Icons.phone_forwarded_rounded
                            : Icons.phone_callback_rounded,
                        color:
                            _currentUserId == call.receiverID
                                ? Colors.green
                                : Colors.orange,
                      ),
                      Text(
                        DateFormat(
                          'hh:mma dd-MM-yyyy',
                        ).format(call.time!).toLowerCase(),
                      ),
                    ],
                  ),
                  tileColor: const Color(0xFFECF2F4),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
