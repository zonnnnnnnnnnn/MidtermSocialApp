import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/services/firebase_service.dart';
import 'package:social_media_app/theme/app_theme.dart';

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final _nameController = TextEditingController();
  final _avatarUrlController = TextEditingController();
  bool _isLoading = false;

  Future<void> _saveProfile() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a username.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No user to update');
      
      final avatarUrl = _avatarUrlController.text.isNotEmpty 
          ? _avatarUrlController.text 
          : ''; // Empty string if no avatar provided

      // 1. Update Profile in Firebase Auth first
      // We update everything before calling reload() and moving on.
      await user.updateDisplayName(_nameController.text);
      await user.updatePhotoURL(avatarUrl);
      
      // 2. Create user document in Firestore
      await FirebaseService().createUserDocument(user, _nameController.text, avatarUrl);

      // 3. Force a reload of the user object to ensure changes are finalized
      await user.reload();

    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    } finally {
      if(mounted) {
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
        title: const Text('Setup Your Profile'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text('Welcome! Let\'s get you set up.', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 10),
              const Text('Choose a username and an avatar.', style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
              const SizedBox(height: 40),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _avatarUrlController,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Avatar Image URL (Optional)',
                  prefixIcon: Icon(Icons.link)
                ),
              ),
              const SizedBox(height: 30),
              if (_isLoading)
                const CircularProgressIndicator(color: AppTheme.accent)
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveProfile,
                    child: const Text('Save & Continue'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
