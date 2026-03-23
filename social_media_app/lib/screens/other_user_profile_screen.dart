import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/models/post_model.dart';
import 'package:social_media_app/models/user_model.dart';
import 'package:social_media_app/screens/chat_screen.dart';
import 'package:social_media_app/screens/likers_screen.dart';
import 'package:social_media_app/services/firebase_service.dart';
import 'package:social_media_app/theme/app_theme.dart';
import 'package:social_media_app/screens/post_view_screen.dart';

class OtherUserProfileScreen extends StatefulWidget {
  final String userId;
  const OtherUserProfileScreen({super.key, required this.userId});

  @override
  State<OtherUserProfileScreen> createState() => _OtherUserProfileScreenState();
}

class _OtherUserProfileScreenState extends State<OtherUserProfileScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel>(
      stream: _firebaseService.getUserProfile(widget.userId),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final user = userSnapshot.data!;
        final isFollowing = user.followers.contains(_currentUserId);

        return StreamBuilder<List<PostModel>>(
          stream: _firebaseService.getPosts(),
          builder: (context, postSnapshot) {
            final allPosts = postSnapshot.data ?? [];
            // STRICT FILTER: show if post is public OR if current user follows the owner OR if current user IS the owner
            final userPosts = allPosts.where((post) {
              return post.userId == widget.userId && 
                     (post.isPublic || isFollowing || widget.userId == _currentUserId);
            }).toList();

            return DefaultTabController(
              length: 1,
              child: Scaffold(
                backgroundColor: AppTheme.bg,
                appBar: AppBar(
                  title: Text(user.username),
                  backgroundColor: AppTheme.bg,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ChatScreen(otherUser: user)),
                      ),
                    ),
                  ],
                ),
                body: NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      SliverToBoxAdapter(
                        child: _buildProfileHeader(user, userPosts.length, isFollowing),
                      ),
                    ];
                  },
                  body: _buildPostsGrid(postSnapshot, userPosts),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProfileHeader(UserModel user, int postCount, bool isFollowing) {
    final bool hasAvatar = user.avatarUrl.isNotEmpty && user.avatarUrl.startsWith('http');

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppTheme.surface,
                backgroundImage: hasAvatar ? NetworkImage(user.avatarUrl) : null,
                child: !hasAvatar ? const Icon(Icons.person, size: 40, color: AppTheme.textSecondary) : null,
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatColumn('Posts', postCount.toString()),
                    _buildStatColumn(
                      'Followers', 
                      user.followers.length.toString(),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserListScreen(userIds: user.followers, title: 'Followers')))
                    ),
                    _buildStatColumn(
                      'Following', 
                      user.following.length.toString(),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserListScreen(userIds: user.following, title: 'Following')))
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (isFollowing) {
                      _firebaseService.unfollowUser(_currentUserId!, widget.userId);
                    } else {
                      _firebaseService.followUser(_currentUserId!, widget.userId);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFollowing ? AppTheme.surface : AppTheme.accent,
                    foregroundColor: isFollowing ? AppTheme.textPrimary : Colors.black,
                  ),
                  child: Text(isFollowing ? 'Unfollow' : 'Follow'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ChatScreen(otherUser: user)),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.accent),
                    foregroundColor: AppTheme.accent,
                  ),
                  child: const Text('Message'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildPostsGrid(AsyncSnapshot<List<PostModel>> snapshot, List<PostModel> userPosts) {
     if (snapshot.connectionState == ConnectionState.waiting && userPosts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (userPosts.isEmpty) {
      return const Center(child: Text('This user\'s private posts are hidden.', style: TextStyle(color: AppTheme.textSecondary)));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: userPosts.length,
      itemBuilder: (context, index) {
        final post = userPosts[index];
        return GestureDetector(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PostViewScreen(post: post))),
          child: Stack(
            children: [
              Positioned.fill(child: Image.network(post.imageUrl, fit: BoxFit.cover, errorBuilder: (c,o,s) => Container(color: AppTheme.surface,))),
              if (!post.isPublic)
                const Positioned(
                  top: 4,
                  right: 4,
                  child: Icon(Icons.lock, size: 14, color: Colors.white70),
                ),
            ],
          ),
        );
      },
    );
  }
}
