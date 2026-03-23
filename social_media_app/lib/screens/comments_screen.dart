import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/models/comment_model.dart';
import 'package:social_media_app/services/firebase_service.dart';
import 'package:social_media_app/theme/app_theme.dart';

class CommentsScreen extends StatefulWidget {
  final String postId;
  const CommentsScreen({super.key, required this.postId});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final _commentController = TextEditingController();
  final _firebaseService = FirebaseService();

  void _postComment() async {
    final user = await _firebaseService.getCurrentUser(); // Corrected: Added await
    if (user == null || _commentController.text.isEmpty) return;

    final newComment = CommentModel(
      id: '', // Firestore will generate this
      userId: user.uid,
      username: user.displayName ?? 'Anonymous',
      avatarUrl: user.photoURL ?? 'assets/images/profile.webp',
      text: _commentController.text,
      timestamp: DateTime.now(),
    );

    try {
      await _firebaseService.addComment(widget.postId, newComment);
      _commentController.clear();
      FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error posting comment: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Comments'),
        backgroundColor: AppTheme.bg,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<CommentModel>>(
              stream: _firebaseService.getComments(widget.postId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No comments yet.', style: TextStyle(color: AppTheme.textSecondary)));
                }
                final comments = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 10),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: comment.avatarUrl.startsWith('http')
                            ? NetworkImage(comment.avatarUrl)
                            : AssetImage(comment.avatarUrl) as ImageProvider,
                      ),
                      title: Text(comment.username, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                      subtitle: Text(comment.text, style: const TextStyle(color: AppTheme.textSecondary)),
                    );
                  },
                );
              },
            ),
          ),
          _buildCommentInputField(),
        ],
      ),
    );
  }

  Widget _buildCommentInputField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.divider, width: 0.5)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Add a comment...',
                  hintStyle: TextStyle(color: AppTheme.textSecondary),
                  border: InputBorder.none,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: AppTheme.accent),
              onPressed: _postComment,
            ),
          ],
        ),
      ),
    );
  }
}
