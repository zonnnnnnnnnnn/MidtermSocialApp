import 'package:flutter/material.dart';
import 'package:social_media_app/models/post_model.dart';
import 'package:social_media_app/widgets/post_card.dart';
import 'package:social_media_app/theme/app_theme.dart';

// This screen is responsible for displaying a single post in a focused view.
class PostViewScreen extends StatelessWidget {
  final PostModel post;

  const PostViewScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: Text(post.username), 
        backgroundColor: AppTheme.bg,
        elevation: 0,
      ),
      body: SingleChildScrollView( // Keeps the post scrollable to prevent overflow
        child: PostCard(
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
          isPublic: post.isPublic, // Passed correctly to ensure lock icon shows up if private
        ),
      ),
    );
  }
}
