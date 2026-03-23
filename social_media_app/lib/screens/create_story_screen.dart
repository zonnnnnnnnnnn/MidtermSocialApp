import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:social_media_app/models/story_model.dart';
import 'package:social_media_app/services/firebase_service.dart';
import 'package:social_media_app/theme/app_theme.dart';

// This screen allows a logged-in user to create a new story.
class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  final _imageUrlController = TextEditingController();
  bool _isLoading = false;
  bool _isPublic = true; // State for privacy setting

  @override
  void dispose() {
    _imageUrlController.dispose();
    super.dispose();
  }

  // This function is called when the user taps the 'Share' button.
  Future<void> _createStory() async {
    if (_imageUrlController.text.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an image URL for your story.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. GET USER DATA: We fetch the current user's information.
      final user = await FirebaseService().getCurrentUser();
      if (user == null) throw Exception('No user logged in!');

      // 2. PREPARE THE DATA MODEL
      final newStory = StoryModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: user.displayName ?? 'Anonymous User',
        userId: user.uid,
        imageUrl: user.photoURL ?? 'assets/images/profile.webp',
        storyImageUrl: _imageUrlController.text,
        timestamp: DateTime.now(),
        isOwn: true,
        isPublic: _isPublic, // Set privacy setting
      );

      // 3. SAVE TO DATABASE
      await FirebaseService().addStory(newStory);

      // 4. FINISH
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Story created successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating story: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.bg,
        title: const Text('Create Story', style: TextStyle(color: AppTheme.textPrimary)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createStory,
            child: const Text(
              'Share',
              style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Share a moment', style: TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  const Text(
                    'Paste a link to an image to share it with your friends for 24 hours.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  TextField(
                    controller: _imageUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Image URL',
                      prefixIcon: Icon(Icons.link),
                    ),
                    style: const TextStyle(color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Public Story', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                      Switch(
                        value: _isPublic,
                        onChanged: (value) => setState(() => _isPublic = value),
                        activeColor: AppTheme.accent,
                      ),
                    ],
                  ),
                  Text(
                    _isPublic ? 'Everyone can see this story.' : 'Only your followers can see this story.',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(child: CircularProgressIndicator(color: AppTheme.accent)),
            ),
        ],
      ),
    );
  }
}
