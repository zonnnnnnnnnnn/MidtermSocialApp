import 'package:cloud_firestore/cloud_firestore.dart';

// This class defines the data structure for a User Profile document in Firestore.
// It is separate from the Firebase Auth User object and is used to store
// public-facing information and social graph data (followers/following).
class UserModel {
  final String id;          // The unique ID of the user (matches their Firebase Auth UID).
  final String username;    // The user's public display name.
  final String email;       // The user's email address.
  final String avatarUrl;   // The URL for the user's profile picture.
  final List<String> followers; // A list of user IDs who are following this user.
  final List<String> following; // A list of user IDs that this user is following.
  final List<String> bookmarks; // A list of post IDs that the user has bookmarked.

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.avatarUrl,
    this.followers = const [],
    this.following = const [],
    this.bookmarks = const [],
  });

  // This factory constructor takes a raw document from Firestore and converts
  // it into a clean, predictable UserModel object.
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      username: data['username'] ?? '',
      email: data['email'] ?? '',
      avatarUrl: data['avatarUrl'] ?? '',
      followers: List<String>.from(data['followers'] ?? []),
      following: List<String>.from(data['following'] ?? []),
      bookmarks: List<String>.from(data['bookmarks'] ?? []),
    );
  }

  // This function, 'toMap', converts the UserModel object into a Map
  // that can be easily stored in Firestore.
  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email,
      'avatarUrl': avatarUrl,
      'followers': followers,
      'following': following,
      'bookmarks': bookmarks,
    };
  }
}
