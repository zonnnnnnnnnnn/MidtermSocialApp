import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/models/message_model.dart';
import 'package:social_media_app/models/notification_model.dart';
import 'package:social_media_app/models/post_model.dart';
import 'package:social_media_app/models/story_model.dart';
import 'package:social_media_app/models/user_model.dart';
import 'package:social_media_app/screens/chat_list_screen.dart';
import 'package:social_media_app/screens/create_story_screen.dart';
import 'package:social_media_app/screens/notifications_screen.dart';
import 'package:social_media_app/screens/story_viewer_screen.dart';
import 'package:social_media_app/services/firebase_service.dart';
import 'package:social_media_app/theme/app_theme.dart';
import 'package:social_media_app/widgets/post_card.dart';
import 'package:social_media_app/widgets/story_bubble.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  User? _user;
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return StreamBuilder<UserModel>(
      stream: _firebaseService.getUserProfile(_user!.uid),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final currentUserProfile = userSnapshot.data!;
        final following = currentUserProfile.following;

        return CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: AppTheme.bg,
              floating: true,
              title: RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(text: 'GAME', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.accent, letterSpacing: 3)),
                    TextSpan(text: 'FEED', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.textPrimary, letterSpacing: 3)),
                  ],
                ),
              ),
              actions: [
                // Notifications Icon with Red Badge
                StreamBuilder<List<NotificationModel>>(
                  stream: _firebaseService.getNotifications(_user!.uid),
                  builder: (context, snapshot) {
                    final unreadCount = snapshot.data?.where((n) => !n.isRead).length ?? 0;
                    
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        IconButton(
                          icon: Icon(
                            unreadCount > 0 ? Icons.favorite : Icons.favorite_border, 
                            color: unreadCount > 0 ? AppTheme.accentPink : AppTheme.textPrimary
                          ),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 12,
                                minHeight: 12,
                              ),
                              child: Text(
                                unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    );
                  }
                ),
              
                // Messages Icon with Red Badge
                StreamBuilder<List<MessageModel>>(
                  stream: _firebaseService.getUnreadMessages(_user!.uid),
                  builder: (context, snapshot) {
                    final unreadMessages = snapshot.data?.length ?? 0;

                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chat_bubble_outline, color: AppTheme.textPrimary),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListScreen())),
                        ),
                        if (unreadMessages > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 12,
                                minHeight: 12,
                              ),
                              child: Text(
                                unreadMessages.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),

            SliverToBoxAdapter(
              child: StreamBuilder<List<StoryModel>>(
                stream: _firebaseService.getStories(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(height: 100);
                  }
                  
                  final allStories = snapshot.data ?? [];
                  // STRICT FILTER: Show if (is public) OR (is author) OR (is following author)
                  final visibleStories = allStories.where((story) {
                    final isAuthor = story.userId == _user!.uid;
                    final isFollowing = following.contains(story.userId);
                    return story.isPublic || isAuthor || isFollowing;
                  }).toList();

                  final userStoriesMap = <String, List<StoryModel>>{};
                  for (var story in visibleStories) {
                    (userStoriesMap[story.userId] ??= []).add(story);
                  }
                  final storyBubbles = userStoriesMap.values.toList();

                  return SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: storyBubbles.length + 1,
                      itemBuilder: (_, i) {
                        if (i == 0) {
                          return GestureDetector(
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateStoryScreen())),
                            child: StoryBubble(
                              name: 'Your Story',
                              imageUrl: _user?.photoURL ?? '',
                              isOwn: true,
                            ),
                          );
                        }
                        
                        final userStoryList = storyBubbles[i - 1];
                        final firstStory = userStoryList.first;
                        final hasUnviewed = userStoryList.any((s) => !s.viewedBy.contains(_user?.uid));

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => StoryViewerScreen(stories: userStoryList, initialIndex: 0)));
                          },
                          child: StoryBubble(
                            name: firstStory.name,
                            imageUrl: firstStory.imageUrl,
                            hasStory: hasUnviewed,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            const SliverToBoxAdapter(child: Divider(color: AppTheme.divider, height: 1)),

            StreamBuilder<List<PostModel>>(
              stream: _firebaseService.getPosts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const SliverFillRemaining(child: Center(child: Text('No posts yet.')));
                }

                final allPosts = snapshot.data!;
                // STRICT FILTER: Show if (is public) OR (is author) OR (is following author)
                final visiblePosts = allPosts.where((post) {
                  final isAuthor = post.userId == _user!.uid;
                  final isFollowing = following.contains(post.userId);
                  return post.isPublic || isAuthor || isFollowing;
                }).toList();

                if (visiblePosts.isEmpty) {
                  return const SliverFillRemaining(child: Center(child: Text('No posts yet.', style: TextStyle(color: AppTheme.textSecondary))));
                }

                return SliverList(delegate: SliverChildBuilderDelegate((context, index) {
                  final post = visiblePosts[index];
                  return PostCard(
                    authorId: post.userId,
                    username: post.username,
                    location: post.location,
                    avatarUrl: post.avatarUrl,
                    imageUrl: post.imageUrl,
                    likes: post.likes,
                    comments: post.comments,
                    caption: post.caption,
                    postId: post.id,
                    timestamp: post.timestamp,
                    likedBy: post.likedBy,
                    isPublic: post.isPublic, // Pass privacy status
                  );
                }, childCount: visiblePosts.length));
              },
            ),
          ],
        );
      }
    );
  }
}
