import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:test/core/extensions.dart';

import '../../../services/service_locator.dart';
import '../../models/chat_room_model.dart';
import '../../repositories/chat_repository.dart';

class ChatListTile extends StatelessWidget {
  final ChatRoomModel chat;
  final String currentUserId;
  final VoidCallback onTap;
  const ChatListTile({
    super.key,
    required this.chat,
    required this.currentUserId,
    required this.onTap,
  });

  String _getOtherUsername() {
    try {
      final otherUserId = chat.participants.firstWhere(
        (id) => id != currentUserId,
        orElse: () => 'Unknown User',
      );
      return chat.participantsName?[otherUserId] ?? "Unknown User";
    } catch (e) {
      return "Unknown User";
    }
  }

  @override
  Widget build(BuildContext context) {
    final otherUserId = chat.participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => 'Unknown User',
    );

    String? lastMessageTime;
    if (chat.lastMessageTime != null) {
      final dt =
          chat.lastMessageTime is DateTime
              ? chat.lastMessageTime
              : (chat.lastMessageTime as dynamic).toDate?.call() ??
                  chat.lastMessageTime;
      lastMessageTime = DateFormat('h:mm a').format(dt);
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withAlpha((0.08 * 255).round()),
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      child: ListTile(
        tileColor: const Color(0xFFECF2F4),
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColorDark,
          foregroundImage: NetworkImage(
            "https://ui-avatars.com/api/?name=${chat.participantsName?[otherUserId] ?? 'U'}&background=${Theme.of(context).primaryColorDark}&color=fff",
          ),
          child: Text(
            (chat.participantsName?[otherUserId] ?? 'U')[0].toUpperCase(),
            style: TextStyle(
              color: Theme.of(context).scaffoldBackgroundColor,
              fontSize: 20,
            ),
          ),
        ),
        title: Text(
          _getOtherUsername(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: Text(
                chat.lastMessage ?? "",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (lastMessageTime != null)
              Text(
                lastMessageTime,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
           4.0.spaceHeight,
            StreamBuilder<int>(
              stream: getIt<ChatRepository>().getUnreadCount(
                chat.id,
                currentUserId,
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data == 0) {
                  return const SizedBox();
                }
                return Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    snapshot.data.toString(),
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

