import 'package:flutter/material.dart';
import 'package:social_media_app/models/user_model.dart';
import 'package:social_media_app/screens/other_user_profile_screen.dart';
import 'package:social_media_app/services/firebase_service.dart';
import 'package:social_media_app/theme/app_theme.dart';

class UserListScreen extends StatelessWidget {
  final List<String> userIds;
  final String title;

  const UserListScreen({super.key, required this.userIds, required this.title});

  @override
  Widget build(BuildContext context) {
    final FirebaseService firebaseService = FirebaseService();

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppTheme.bg,
        elevation: 0,
      ),
      body: FutureBuilder<List<UserModel>>(
        future: firebaseService.getUsersByIds(userIds),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final users = snapshot.data ?? [];

          if (users.isEmpty) {
            return const Center(
              child: Text('No users found.', style: TextStyle(color: AppTheme.textSecondary)),
            );
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];

              return ListTile(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => OtherUserProfileScreen(userId: user.id))
                  );
                },
                leading: CircleAvatar(
                  backgroundColor: AppTheme.surface,
                  backgroundImage: user.avatarUrl.isNotEmpty ? NetworkImage(user.avatarUrl) : null,
                  child: user.avatarUrl.isEmpty ? const Icon(Icons.person, color: AppTheme.textSecondary) : null,
                ),
                title: Text(
                  user.username,
                  style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  user.email,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Keep the old name for compatibility if needed elsewhere, but point it to the new one.
class LikersScreen extends UserListScreen {
  const LikersScreen({super.key, required super.userIds}) : super(title: 'Likes');
}
