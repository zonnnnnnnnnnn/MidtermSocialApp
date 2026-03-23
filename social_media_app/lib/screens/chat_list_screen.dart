import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/models/user_model.dart';
import 'package:social_media_app/screens/chat_screen.dart';
import 'package:social_media_app/services/firebase_service.dart';
import 'package:social_media_app/theme/app_theme.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final FirebaseService firebaseService = FirebaseService();

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        title: const Text('Messages', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: firebaseService.getChatUsers(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final users = snapshot.data ?? [];

          if (users.isEmpty) {
            return const Center(
              child: Text(
                'No conversations yet.\nFollow someone to start chatting!',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            );
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ChatScreen(otherUser: user)),
                ),
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(user.avatarUrl),
                ),
                title: Text(
                  user.username,
                  style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Tap to chat',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textSecondary),
              );
            },
          );
        },
      ),
    );
  }
}
