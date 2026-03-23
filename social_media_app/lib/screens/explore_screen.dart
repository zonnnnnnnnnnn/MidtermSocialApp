import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/models/post_model.dart';
import 'package:social_media_app/models/user_model.dart';
import 'package:social_media_app/screens/post_view_screen.dart';
import 'package:social_media_app/screens/other_user_profile_screen.dart';
import 'package:social_media_app/services/firebase_service.dart';
import 'package:social_media_app/theme/app_theme.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Explore'),
        backgroundColor: AppTheme.bg,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: UserSearchDelegate(),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<UserModel>(
        stream: _firebaseService.getUserProfile(_currentUser!.uid),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final following = userSnapshot.data?.following ?? [];

          return StreamBuilder<List<PostModel>>(
            stream: _firebaseService.getPosts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No posts to explore yet.'));
              }

              final allPosts = snapshot.data!;
              // STRICT FILTER: Show only if (is public) OR (current user is author) OR (current user follows author)
              final visiblePosts = allPosts.where((post) {
                final isAuthor = post.userId == _currentUser!.uid;
                final isFollowing = following.contains(post.userId);
                return post.isPublic || isAuthor || isFollowing;
              }).toList();

              if (visiblePosts.isEmpty) {
                return const Center(child: Text('No posts to explore yet.', style: TextStyle(color: AppTheme.textSecondary)));
              }

              return GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemCount: visiblePosts.length,
                itemBuilder: (context, index) {
                  final post = visiblePosts[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => PostViewScreen(post: post),
                        ),
                      );
                    },
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.network(
                            post.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(color: AppTheme.surface),
                          ),
                        ),
                        if (!post.isPublic)
                          const Positioned(
                            top: 8,
                            right: 8,
                            child: Icon(Icons.lock, size: 16, color: Colors.white70),
                          ),
                      ],
                    ),
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

class UserSearchDelegate extends SearchDelegate {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  ThemeData appBarTheme(BuildContext context) {
    return AppTheme.dark.copyWith(
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: AppTheme.textSecondary),
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    if (query.isEmpty) {
      return const Center(child: Text('Search for users...', style: TextStyle(color: AppTheme.textSecondary)));
    }

    return FutureBuilder<List<UserModel>>(
      future: _firebaseService.searchUsers(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final users = snapshot.data ?? [];

        if (users.isEmpty) {
          return const Center(child: Text('No users found.', style: TextStyle(color: AppTheme.textSecondary)));
        }

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return ListTile(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => OtherUserProfileScreen(userId: user.id),
                  ),
                );
              },
              leading: CircleAvatar(
                backgroundImage: NetworkImage(user.avatarUrl),
              ),
              title: Text(user.username, style: const TextStyle(color: AppTheme.textPrimary)),
              subtitle: Text(user.email, style: const TextStyle(color: AppTheme.textSecondary)),
            );
          },
        );
      },
    );
  }
}
