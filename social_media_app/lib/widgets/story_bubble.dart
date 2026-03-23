import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StoryBubble extends StatelessWidget {
  final String name;
  final String imageUrl;
  final bool isOwn;
  final bool hasStory;

  const StoryBubble({
    super.key,
    required this.name,
    required this.imageUrl,
    this.isOwn = false,
    this.hasStory = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          if (isOwn)
            _buildOwnStory()
          else
            _buildStoryRing(),
          const SizedBox(height: 6),
          Text(
            name,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnStory() {
    // Validate if the image URL is usable
    final bool hasValidImage = imageUrl.isNotEmpty && imageUrl.startsWith('http');

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.card,
            border: Border.all(color: AppTheme.divider, width: 2),
          ),
          child: ClipOval(
            child: hasValidImage
              ? Image.network(
                  imageUrl, 
                  fit: BoxFit.cover, 
                  errorBuilder: (_, __, ___) => const Icon(Icons.person, color: AppTheme.textSecondary, size: 30)
                )
              : const Icon(Icons.person, color: AppTheme.textSecondary, size: 30),
          ),
        ),
        Positioned(
          bottom: -2,
          right: -2,
          child: Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: AppTheme.accent,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, size: 16, color: Colors.black),
          ),
        ),
      ],
    );
  }

  Widget _buildStoryRing() {
    final bool hasValidImage = imageUrl.isNotEmpty && imageUrl.startsWith('http');

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: hasStory
            ? const LinearGradient(
                colors: [AppTheme.accent, AppTheme.accentPink],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: hasStory ? null : AppTheme.divider,
      ),
      padding: const EdgeInsets.all(2.5),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.bg,
        ),
        padding: const EdgeInsets.all(2),
        child: ClipOval(
          child: hasValidImage
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.person, color: AppTheme.textSecondary, size: 30),
              )
            : const Icon(Icons.person, color: AppTheme.textSecondary, size: 30),
        ),
      ),
    );
  }
}
