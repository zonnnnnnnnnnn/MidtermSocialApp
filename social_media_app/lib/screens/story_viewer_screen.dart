import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:social_media_app/models/story_model.dart';
import 'package:social_media_app/services/firebase_service.dart';
import 'package:social_media_app/theme/app_theme.dart';

// This screen provides a full-screen, immersive experience for viewing stories.
class StoryViewerScreen extends StatefulWidget {
  // It receives a list of stories (all from the same user) and the index to start on.
  final List<StoryModel> stories;
  final int initialIndex;

  const StoryViewerScreen({
    super.key,
    required this.stories,
    required this.initialIndex,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

// It uses a SingleTickerProviderStateMixin to provide a 'ticker' for the heart animation.
class _StoryViewerScreenState extends State<StoryViewerScreen> with SingleTickerProviderStateMixin {
  late PageController _pageController; // Manages the swiping between stories.
  late AnimationController _animController; // Manages the heart animation.
  int _currentIndex = 0;
  bool _isLiked = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _animController = AnimationController(duration: const Duration(milliseconds: 400), vsync: this);

    // This listener updates the UI when the user swipes to a new story.
    _pageController.addListener(() {
      if (_pageController.page?.round() != _currentIndex) {
        setState(() {
          _currentIndex = _pageController.page!.round();
          _isLiked = false; // Reset the like status for the new story.
        });
      }
    });
  }

  // This function is triggered on a double-tap to show the heart animation.
  void _onDoubleTap() {
    setState(() => _isLiked = true);
    _animController.forward(from: 0).then((_) => _animController.reverse());
  }

  // Shows a confirmation dialog before deleting a story.
  void _showDeleteConfirmation(String storyId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Story'),
        content: const Text('Are you sure you want to delete this story?'),
        actions: [
          TextButton(child: const Text('No'), onPressed: () => Navigator.of(ctx).pop()),
          TextButton(
            child: const Text('Yes'),
            onPressed: () {
              Navigator.of(ctx).pop();
              FirebaseService().deleteStory(storyId).then((_) {
                if (widget.stories.length == 1) {
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Story Deleted.')));
                  Navigator.of(context).pop();
                }
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stories.isEmpty || _currentIndex >= widget.stories.length) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: Text('Story not found.', style: TextStyle(color: Colors.white))));
    }
    final story = widget.stories[_currentIndex];
    final bool isAuthor = _currentUserId == story.userId;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onDoubleTap: _onDoubleTap,
        child: Stack(
          children: [
            // The PageView is what allows the user to swipe left and right.
            PageView.builder(
              controller: _pageController,
              itemCount: widget.stories.length,
              itemBuilder: (context, index) {
                return Center(
                  child: Image.network(widget.stories[index].storyImageUrl, fit: BoxFit.contain),
                );
              },
            ),
            // This is the animated heart that appears on double-tap.
            Center(
              child: ScaleTransition(
                scale: Tween(begin: 0.5, end: 1.5).animate(CurvedAnimation(parent: _animController, curve: Curves.elasticOut)),
                child: FadeTransition(
                  opacity: Tween<double>(begin: 1.0, end: 0.0).animate(_animController),
                  child: const Icon(Icons.favorite, color: Colors.white, size: 100),
                ),
              ),
            ),
            // This is the UI overlay at the top of the screen.
            Positioned(
              top: 40,
              left: 10,
              right: 10,
              child: Column(
                children: [
                  // Progress bars showing how many stories there are.
                  Row(
                    children: List.generate(widget.stories.length, (index) {
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          height: 2.5,
                          color: index == _currentIndex ? Colors.white : Colors.white38,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  // User info and close button.
                  ListTile(
                    leading: CircleAvatar(backgroundImage: NetworkImage(story.imageUrl)),
                    title: Text(story.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
             // This is the UI overlay at the bottom of the screen.
            Positioned(
              bottom: 20,
              left: 8,
              right: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // The delete button only appears if the viewer is the author.
                  if(isAuthor)
                    IconButton(
                      onPressed: () => _showDeleteConfirmation(story.id),
                      icon: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
                      tooltip: 'Delete Story',
                    ),
                  const Spacer(),
                  // The like button.
                  IconButton(
                    onPressed: () {
                       setState(() => _isLiked = !_isLiked);
                       if (_isLiked) {
                         _animController.forward(from: 0).then((_) => _animController.reverse());
                       }
                    },
                    icon: Icon(
                      _isLiked ? Icons.favorite : Icons.favorite_border,
                      color: _isLiked ? Colors.red : Colors.white,
                      size: 30,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
    super.dispose();
  }
}
