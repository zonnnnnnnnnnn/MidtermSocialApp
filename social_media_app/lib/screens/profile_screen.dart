import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/models/post_model.dart';
import 'package:social_media_app/models/user_model.dart';
import 'package:social_media_app/screens/likers_screen.dart';
import 'package:social_media_app/services/firebase_service.dart';
import 'package:social_media_app/theme/app_theme.dart';
import 'package:social_media_app/screens/post_view_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  User? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    final user = await _firebaseService.getCurrentUser();
    if (mounted) {
      setState(() {
        _user = user;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateProfile(String name, String avatarUrl) async {
    try {
      if (_user != null) {
        await _user!.updateDisplayName(name);
        await _user!.updatePhotoURL(avatarUrl);
        await _firebaseService.createUserDocument(_user!, name, avatarUrl);
        await _user!.reload();
        await _loadUserData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    }
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _user?.displayName);
    final avatarController = TextEditingController(text: _user?.photoURL);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Edit Profile', style: TextStyle(color: AppTheme.textPrimary)),
        content: SingleChildScrollView( 
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Username'),
                style: const TextStyle(color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: avatarController,
                decoration: const InputDecoration(labelText: 'Avatar URL'),
                style: const TextStyle(color: AppTheme.textPrimary),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              await _updateProfile(nameController.text, avatarController.text);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Logout', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('Are you sure you want to logout?', style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _firebaseService.signOut();
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _user == null) {
      return const Scaffold(
        backgroundColor: AppTheme.bg,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return StreamBuilder<UserModel>(
      stream: _firebaseService.getUserProfile(_user!.uid),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const Scaffold(
            backgroundColor: AppTheme.bg,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userProfile = userSnapshot.data!;

        return StreamBuilder<List<PostModel>>(
          stream: _firebaseService.getPosts(),
          builder: (context, postSnapshot) {
            final allPosts = postSnapshot.data ?? [];
            final userPosts = allPosts.where((post) => post.userId == _user!.uid).toList();
            
            // Filter liked and bookmarked posts based on privacy settings and following status
            final likedPosts = allPosts.where((post) {
              final isOwner = post.userId == _user!.uid;
              final isFollowing = userProfile.following.contains(post.userId);
              return post.likedBy.contains(_user!.uid) && (post.isPublic || isOwner || isFollowing);
            }).toList();

            final bookmarkedPosts = allPosts.where((post) {
              final isOwner = post.userId == _user!.uid;
              final isFollowing = userProfile.following.contains(post.userId);
              return userProfile.bookmarks.contains(post.id) && (post.isPublic || isOwner || isFollowing);
            }).toList();

            return DefaultTabController(
              length: 3,
              child: Scaffold(
                backgroundColor: AppTheme.bg,
                body: NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      SliverAppBar(
                        backgroundColor: AppTheme.bg,
                        expandedHeight: 300,
                        pinned: true,
                        flexibleSpace: FlexibleSpaceBar(
                          background: SingleChildScrollView(
                            physics: const NeverScrollableScrollPhysics(),
                            child: _buildProfileHeader(userProfile, userPosts.length),
                          ),
                        ),
                        actions: [
                          IconButton(
                            tooltip: "Edit Profile",
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: _showEditProfileDialog,
                          ),
                          IconButton(
                            tooltip: "Logout",
                            icon: const Icon(Icons.logout),
                            onPressed: _showLogoutConfirmation,
                          ),
                        ],
                        bottom: const TabBar(
                          indicatorColor: AppTheme.accent,
                          tabs: [
                            Tab(icon: Icon(Icons.grid_on)),
                            Tab(icon: Icon(Icons.favorite_border)),
                            Tab(icon: Icon(Icons.bookmark_border)),
                          ],
                        ),
                      ),
                    ];
                  },
                  body: TabBarView(
                    children: [
                      _buildPostsGrid(postSnapshot, userPosts, emptyMessage: 'You have not created any posts yet.'),
                      _buildPostsGrid(postSnapshot, likedPosts, emptyMessage: 'You have not liked any posts yet.'),
                      _buildPostsGrid(postSnapshot, bookmarkedPosts, emptyMessage: 'You have no bookmarked posts.'),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProfileHeader(UserModel user, int postCount) {
    final bool hasAvatar = user.avatarUrl.isNotEmpty && user.avatarUrl.startsWith('http');

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(height: 16),
          Text(
            user.username,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            user.email,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
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
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsGrid(AsyncSnapshot<List<PostModel>> snapshot, List<PostModel> posts, {required String emptyMessage}) {
    if (snapshot.connectionState == ConnectionState.waiting && posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (posts.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => PostViewScreen(post: post)),
          ),
          child: Image.network(
            post.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (c, o, s) => Container(color: AppTheme.surface),
          ),
        );
      },
    );
  }
}
