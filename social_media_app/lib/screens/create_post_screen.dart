import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:social_media_app/models/post_model.dart';
import 'package:social_media_app/services/firebase_service.dart';
import 'package:social_media_app/theme/app_theme.dart';

// This screen allows a logged-in user to create a new post.
class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  // TextEditingControllers are used to get the text from the input fields.
  final _captionController = TextEditingController();
  final _locationController = TextEditingController();
  final _imageUrlController = TextEditingController();
  bool _isLoading = false;
  bool _isPublic = true; // State for privacy setting

  // This function is called when the user taps the 'Post' button.
  Future<void> _createPost() async {
    // First, we do a quick validation check.
    if (_imageUrlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an image URL.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. GET USER DATA: We fetch the current user's information.
      final User? user = await FirebaseService().getCurrentUser();
      if (user == null) throw Exception('No user logged in');

      // 2. WORKAROUND: GET IMAGE URL
      // Instead of uploading an image file (which requires a paid Firebase plan),
      // we simply take the URL string that the user has pasted in the text field.
      final String imageUrl = _imageUrlController.text;

      // 3. PREPARE THE DATA MODEL
      // We create a `PostModel` object, which is a structured way to hold all the
      // information about our new post.
      final newPost = PostModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // A unique ID based on the current time.
        username: user.displayName ?? 'Anonymous User',
        userId: user.uid,
        location: _locationController.text.isEmpty ? 'A Distant Land' : _locationController.text,
        avatarUrl: user.photoURL ?? 'assets/images/profile.webp',
        imageUrl: imageUrl, // Here we use the URL from the text field.
        likes: 0,
        comments: 0,
        caption: _captionController.text,
        timestamp: DateTime.now(),
        likedBy: [],
        isPublic: _isPublic, // Set privacy setting
      );

      // 4. SAVE TO DATABASE
      // We call our FirebaseService to save the new post object to the Firestore database.
      await FirebaseService().addPost(newPost);

      // 5. FINISH
      // If everything was successful, we navigate back to the previous screen.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post created successfully!')),
        );
        Navigator.of(context).pop();
      }

    } catch (e) {
      // If any error occurs, we show an error message.
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating post: $e')),
        );
      }
    } finally {
      // This block always runs, whether there was an error or not.
      // We use it to make sure the loading indicator is always hidden.
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
        backgroundColor: AppTheme.bg,
        elevation: 0,
        title: const Text('Create Post', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.close, color: AppTheme.textPrimary), onPressed: () => Navigator.pop(context)),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createPost,
            child: const Text('Post', style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Image URL', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                // This is the TextField where the user pastes the image link.
                TextField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(hintText: 'Paste a direct link to an image...', prefixIcon: Icon(Icons.link)),
                  style: const TextStyle(color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 24),
                const Text('Caption', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _captionController,
                  maxLines: 4,
                  decoration: const InputDecoration(hintText: 'Write a caption...'),
                  style: const TextStyle(color: AppTheme.textPrimary),
                ),
                const Divider(color: AppTheme.divider, height: 32),
                const Text('Location', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _locationController,
                  decoration: const InputDecoration(hintText: 'Add location', prefixIcon: Icon(Icons.location_on_outlined)),
                  style: const TextStyle(color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Public Post', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                    Switch(
                      value: _isPublic,
                      onChanged: (value) => setState(() => _isPublic = value),
                      activeColor: AppTheme.accent,
                    ),
                  ],
                ),
                Text(
                  _isPublic ? 'Everyone can see this post.' : 'Only your followers can see this post.',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          // A simple loading overlay that appears while the post is being created.
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
