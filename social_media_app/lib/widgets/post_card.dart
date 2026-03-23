import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:social_media_app/models/user_model.dart';
import 'package:social_media_app/screens/comments_screen.dart';
import 'package:social_media_app/screens/likers_screen.dart';
import 'package:social_media_app/screens/other_user_profile_screen.dart';
import 'package:social_media_app/theme/app_theme.dart';
import 'package:social_media_app/services/firebase_service.dart';

class PostCard extends StatefulWidget {
  final String username;
  final String location;
  final String avatarUrl;
  final String imageUrl;
  final int likes;
  final int comments;
  final String caption;
  final String postId;
  final String authorId;
  final DateTime timestamp;
  final List<String> likedBy;
  final bool isPublic; // New property

  const PostCard({
    super.key,
    required this.username,
    required this.location,
    required this.avatarUrl,
    required this.imageUrl,
    required this.likes,
    required this.comments,
    required this.caption,
    required this.postId,
    required this.authorId,
    required this.timestamp,
    required this.likedBy,
    this.isPublic = true, // Default to true
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with SingleTickerProviderStateMixin {
  late AnimationController _heartController;
  late Animation<double> _heartScale;
  final FirebaseService _firebaseService = FirebaseService();
  
  String? _currentUserId;
  late bool _liked;
  late int _likeCount;
  late List<String> _currentLikedBy;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _initializeState();

    _heartController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _heartScale = Tween(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.elasticOut),
    );
  }

  void _initializeState() {
    _liked = widget.likedBy.contains(_currentUserId);
    _likeCount = widget.likes;
    _currentLikedBy = List<String>.from(widget.likedBy);
  }

  @override
  void didUpdateWidget(covariant PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.likedBy != widget.likedBy || oldWidget.likes != widget.likes) {
      setState(() {
        _initializeState();
      });
    }
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  void _navigateToUserProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => OtherUserProfileScreen(userId: widget.authorId)),
    );
  }

  Future<void> _toggleLike() async {
    if (_currentUserId == null) return;

    setState(() {
      if (_liked) {
        _likeCount--;
        _currentLikedBy.remove(_currentUserId);
      } else {
        _likeCount++;
        _currentLikedBy.add(_currentUserId!);
        _heartController.forward().then((_) => _heartController.reverse());
      }
      _liked = !_liked;
    });

    try {
      await _firebaseService.likePost(widget.postId, _currentUserId!);
    } catch (e) {
      setState(() {
        _initializeState();
      });
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _openComments() {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => CommentsScreen(postId: widget.postId)));
  }

  void _openLikers() {
    if (_currentLikedBy.isEmpty) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => LikersScreen(userIds: _currentLikedBy)));
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Delete Post', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('Are you sure you want to delete this post?', style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(child: const Text('No'), onPressed: () => Navigator.of(ctx).pop()),
          TextButton(
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.of(ctx).pop();
              _firebaseService.deletePost(widget.postId);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isAuthor = _currentUserId == widget.authorId;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: GestureDetector(
              onTap: _navigateToUserProfile,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 21,
                    backgroundImage: widget.avatarUrl.startsWith('http') 
                        ? NetworkImage(widget.avatarUrl) 
                        : AssetImage(widget.avatarUrl) as ImageProvider,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(widget.username, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary)),
                            if (!widget.isPublic) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.lock_outline, size: 12, color: AppTheme.textSecondary),
                            ],
                          ],
                        ),
                        Text(widget.location, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                  if (isAuthor)
                    PopupMenuButton<String>(
                      color: AppTheme.surface,
                      onSelected: (value) {
                        if (value == 'delete') _showDeleteConfirmation();
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'delete', 
                          child: Text('Delete Post', style: TextStyle(color: Colors.red))
                        )
                      ],
                      child: const Icon(Icons.more_horiz, color: AppTheme.textSecondary),
                    )
                  else 
                    const SizedBox(width: 48),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(widget.imageUrl, fit: BoxFit.cover, errorBuilder: (c, o, s) => Container(color: AppTheme.surface, child: const Icon(Icons.error))),
            )),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _toggleLike,
                  child: ScaleTransition(
                    scale: _heartScale,
                    child: Icon(_liked ? Icons.favorite : Icons.favorite_border, color: _liked ? AppTheme.accentPink : AppTheme.textSecondary, size: 24),
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: _openComments,
                  child: const Icon(Icons.chat_bubble_outline, color: AppTheme.textSecondary, size: 22),
                ),
                const Spacer(),
                // Bookmark button logic
                if (_currentUserId != null)
                  StreamBuilder<UserModel>(
                    stream: _firebaseService.getUserProfile(_currentUserId!),
                    builder: (context, snapshot) {
                      final isBookmarked = snapshot.data?.bookmarks.contains(widget.postId) ?? false;
                      return GestureDetector(
                        onTap: () => _firebaseService.toggleBookmark(_currentUserId!, widget.postId),
                        child: Icon(
                          isBookmarked ? Icons.bookmark : Icons.bookmark_border, 
                          color: isBookmarked ? AppTheme.accent : AppTheme.textSecondary, 
                          size: 24
                        ),
                      );
                    }
                  ),
              ],
            ),
          ),

          if (_likeCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0),
              child: GestureDetector(
                onTap: _openLikers,
                child: Text('$_likeCount likes', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontSize: 13)),
              ),
            ),

          Padding(
            padding: const EdgeInsets.only(left: 14, right: 14, top: 6, bottom: 4),
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(text: '${widget.username} ', style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary, fontSize: 13)),
                  TextSpan(text: widget.caption, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(left: 14, right: 14, bottom: 14),
            child: Text(_formatTimeAgo(widget.timestamp), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          ),
        ],
      ),
    );
  }

   String _formatTimeAgo(DateTime time) {
    final difference = DateTime.now().difference(time);
    if (difference.inDays > 1) return '${difference.inDays} days ago';
    if (difference.inDays == 1) return '1 day ago';
    if (difference.inHours > 1) return '${difference.inHours} hours ago';
    if (difference.inHours == 1) return '1 hour ago';
    if (difference.inMinutes > 1) return '${difference.inMinutes} minutes ago';
    return 'Just now';
  }
}
