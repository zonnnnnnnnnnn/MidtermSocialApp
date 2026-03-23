import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/models/notification_model.dart';
import 'package:social_media_app/models/user_model.dart';
import 'package:social_media_app/screens/other_user_profile_screen.dart';
import 'package:social_media_app/services/firebase_service.dart';
import 'package:social_media_app/theme/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final FirebaseService firebaseService = FirebaseService();

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: StreamBuilder<UserModel>(
        stream: firebaseService.getUserProfile(currentUserId),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator());
          final currentUser = userSnapshot.data!;

          return StreamBuilder<List<NotificationModel>>(
            stream: firebaseService.getNotifications(currentUserId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final notifications = snapshot.data ?? [];

              if (notifications.isEmpty) {
                return const Center(
                  child: Text('No notifications yet.', style: TextStyle(color: AppTheme.textSecondary)),
                );
              }

              return ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return _NotificationTile(
                    notification: notification,
                    currentUser: currentUser,
                    firebaseService: firebaseService,
                  );
                },
              );
            },
          );
        }
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final UserModel currentUser;
  final FirebaseService firebaseService;

  const _NotificationTile({
    required this.notification,
    required this.currentUser,
    required this.firebaseService,
  });

  @override
  Widget build(BuildContext context) {
    String message = '';
    Widget? trailing;

    if (notification.type == NotificationType.follow) {
      message = 'started following you.';
      final bool isFollowingBack = currentUser.following.contains(notification.fromUserId);
      
      if (!isFollowingBack) {
        trailing = ElevatedButton(
          onPressed: () => firebaseService.followUser(currentUser.id, notification.fromUserId),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accent,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            minimumSize: const Size(80, 30),
            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          child: const Text('Follow Back'),
        );
      }
    }

    return ListTile(
      onTap: () {
        firebaseService.markNotificationAsRead(notification.id);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OtherUserProfileScreen(userId: notification.fromUserId)),
        );
      },
      leading: CircleAvatar(
        backgroundImage: NetworkImage(notification.fromUserAvatar),
        backgroundColor: AppTheme.surface,
        onBackgroundImageError: (_, __) {},
        child: notification.fromUserAvatar.isEmpty ? const Icon(Icons.person, color: AppTheme.textSecondary) : null,
      ),
      title: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: notification.fromUsername,
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            TextSpan(
              text: ' $message',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
      subtitle: Text(
        _formatTimestamp(notification.timestamp),
        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
      ),
      trailing: trailing,
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);
    if (difference.inDays > 0) return '${difference.inDays}d';
    if (difference.inHours > 0) return '${difference.inHours}h';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m';
    return 'now';
  }
}
