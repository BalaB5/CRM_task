import 'package:flutter/material.dart';

import '../../../core/app_router.dart';
import '../../../services/service_locator.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/chat_repository.dart';
import 'chat_message_screen.dart';
import '../widgets/chat_list_tile.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  late final ChatRepository _chatRepository;
  late final String _currentUserId;

  @override
  void initState() {
    _chatRepository = getIt<ChatRepository>();
    var currentUser2 = getIt<AuthRepository>().currentUser;
    _currentUserId = currentUser2?.uid ?? "";

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        title: const Padding(
          padding: EdgeInsets.only(left: 16.0),
          child: Text("Chats"),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        foregroundColor: Colors.white,
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: StreamBuilder(
        stream: _chatRepository.getChatRooms(_currentUserId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("error:${snapshot.error}"));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final chats = snapshot.data!;
          if (chats.isEmpty) {
            return const Center(child: Text("No recent chats"));
          }
          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              return ChatListTile(
                chat: chat,
                currentUserId: _currentUserId,
                onTap: () {
                  final otherUserId = chat.participants.firstWhere(
                    (id) => id != _currentUserId,
                  );
                  final outherUserName =
                      chat.participantsName?[otherUserId] ?? "Unknown";
                  getIt<AppRouter>().push(
                    ChatMessageScreen(
                      receiverId: otherUserId,
                      receiverName: outherUserName,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
     
    );
  }
}
