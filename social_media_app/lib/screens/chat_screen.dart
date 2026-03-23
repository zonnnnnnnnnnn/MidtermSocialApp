import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/models/message_model.dart';
import 'package:social_media_app/models/user_model.dart';
import 'package:social_media_app/services/firebase_service.dart';
import 'package:social_media_app/theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  final UserModel otherUser;
  const ChatScreen({super.key, required this.otherUser});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    // Mark messages as read when the chat is opened
    _markAsRead();
  }

  void _markAsRead() async {
    await _firebaseService.markMessagesAsRead(_currentUserId, widget.otherUser.id);
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final String chatId = _firebaseService.getChatId(_currentUserId, widget.otherUser.id);
    
    final message = MessageModel(
      id: '', 
      senderId: _currentUserId,
      receiverId: widget.otherUser.id,
      text: _messageController.text.trim(),
      timestamp: DateTime.now(),
      chatId: chatId,
    );

    _messageController.clear();
    await _firebaseService.sendMessage(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.surface,
              backgroundImage: widget.otherUser.avatarUrl.isNotEmpty ? NetworkImage(widget.otherUser.avatarUrl) : null,
              child: widget.otherUser.avatarUrl.isEmpty ? const Icon(Icons.person, size: 18, color: AppTheme.textSecondary) : null,
            ),
            const SizedBox(width: 12),
            Text(widget.otherUser.username, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _firebaseService.getMessages(_currentUserId, widget.otherUser.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data ?? [];

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == _currentUserId;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? AppTheme.accent : AppTheme.card,
                          borderRadius: BorderRadius.circular(20).copyWith(
                            bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(20),
                            bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(0),
                          ),
                        ),
                        child: Text(
                          message.text,
                          style: TextStyle(
                            color: isMe ? Colors.black : AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: const TextStyle(color: AppTheme.textSecondary),
                      fillColor: AppTheme.card,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppTheme.accent,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.black),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
