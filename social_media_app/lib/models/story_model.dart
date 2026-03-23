import 'package:cloud_firestore/cloud_firestore.dart';

// This class defines the data structure for a single "MyDay" or Story.
// It acts as a blueprint, ensuring that every story in the app has a consistent
// set of properties. This prevents bugs and makes the code predictable.
class StoryModel {
  final String id;          // The unique ID of the story document.
  final String name;        // The username of the user who created the story.
  final String userId;      // The unique ID of the user who created the story.
  final String imageUrl;    // The URL for the user's avatar, shown in the story bubble.
  final String storyImageUrl; // The URL for the main story image to be displayed full-screen.
  final DateTime timestamp; // When the story was created. Used to make it disappear after 24 hours.
  final bool isOwn;         // A flag to easily identify if the story belongs to the current user.
  final List<String> viewedBy; // A list of user IDs who have viewed this story.
  final bool isPublic;      // New field for privacy

  // The constructor for creating a new StoryModel instance in the app.
  StoryModel({
    required this.id,
    required this.name,
    required this.userId,
    required this.imageUrl,
    required this.storyImageUrl,
    required this.timestamp,
    this.isOwn = false,
    this.viewedBy = const [],
    this.isPublic = true, // Default to public
  });

  // This function, 'toMap', is for converting the StoryModel object into a format
  // that Firestore can understand and store. Firestore stores data in Maps.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'userId': userId,
      'imageUrl': imageUrl,
      'storyImageUrl': storyImageUrl,
      'timestamp': Timestamp.fromDate(timestamp), // Firestore uses its own Timestamp object.
      'isOwn': isOwn,
      'viewedBy': viewedBy,
      'isPublic': isPublic,
    };
  }

  // This factory constructor, 'fromFirestore', does the opposite of toMap.
  // It takes a raw document snapshot from Firestore and converts it back into a
  // clean, predictable StoryModel object that our app's UI can use.
  factory StoryModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return StoryModel(
      id: doc.id,
      name: data['name'] ?? '',
      userId: data['userId'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      storyImageUrl: data['storyImageUrl'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(), // We convert the Firestore Timestamp back to a Dart DateTime.
      isOwn: data['isOwn'] ?? false,
      viewedBy: List<String>.from(data['viewedBy'] ?? []),
      isPublic: data['isPublic'] ?? true,
    );
  }
}
