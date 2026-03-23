import 'package:cloud_firestore/cloud_firestore.dart';

// This class defines the data structure for a single Comment.
// It acts as a blueprint for what a comment object should contain.
class CommentModel {
  final String id;          // The unique ID of the comment document.
  final String userId;      // The ID of the user who wrote the comment.
  final String username;    // The name of the user who wrote the comment.
  final String avatarUrl;   // The URL for the user's avatar.
  final String text;        // The actual content of the comment.
  final DateTime timestamp; // When the comment was posted.

  CommentModel({
    required this.id,
    required this.userId,
    required this.username,
    required this.avatarUrl,
    required this.text,
    required this.timestamp,
  });

  // This factory constructor takes a raw document from Firestore and converts
  // it into a clean, predictable CommentModel object.
  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CommentModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      username: data['username'] ?? 'Anonymous',
      avatarUrl: data['avatarUrl'] ?? '',
      text: data['text'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  // This function, 'toMap', converts the CommentModel object into a Map
  // that can be easily stored in Firestore.
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'avatarUrl': avatarUrl,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
