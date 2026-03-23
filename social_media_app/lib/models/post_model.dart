import 'package:cloud_firestore/cloud_firestore.dart';

// This class defines the data structure for a single Post.
// It acts as a blueprint, ensuring every post in the app has a consistent structure.
class PostModel {
  final String id;
  final String username;
  final String userId;
  final String location;
  final String avatarUrl;
  final String imageUrl;
  final int likes;
  final int comments;
  final String caption;
  final DateTime timestamp;
  final List<String> likedBy;
  final bool isPublic; // New field for privacy

  PostModel({
    required this.id,
    required this.username,
    required this.userId,
    required this.location,
    required this.avatarUrl,
    required this.imageUrl,
    required this.likes,
    required this.comments,
    required this.caption,
    required this.timestamp,
    this.likedBy = const [],
    this.isPublic = true, // Default to public
  });

  // This function, 'toMap', converts the PostModel object into a Map.
  // This format is required to store the data in the Firestore database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'userId': userId,
      'location': location,
      'avatarUrl': avatarUrl,
      'imageUrl': imageUrl,
      'likes': likes,
      'comments': comments,
      'caption': caption,
      'timestamp': Timestamp.fromDate(timestamp),
      'likedBy': likedBy,
      'isPublic': isPublic,
    };
  }

  // This factory constructor does the opposite. It takes a raw document from
  // Firestore and converts it into a clean, predictable PostModel object.
  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PostModel(
      id: doc.id,
      username: data['username'] ?? '',
      userId: data['userId'] ?? '',
      location: data['location'] ?? '',
      avatarUrl: data['avatarUrl'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      likes: data['likes'] ?? 0,
      comments: data['comments'] ?? 0,
      caption: data['caption'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      likedBy: List<String>.from(data['likedBy'] ?? []),
      isPublic: data['isPublic'] ?? true,
    );
  }
}
