import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:social_media_app/firebase_options.dart';
import 'package:social_media_app/models/comment_model.dart';
import 'package:social_media_app/models/message_model.dart';
import 'package:social_media_app/models/notification_model.dart';
import 'package:social_media_app/models/user_model.dart';
import '../models/post_model.dart';
import '../models/story_model.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // --- AUTH METHODS ---
  Future<User?> getCurrentUser() async {
    return _auth.currentUser;
  }

  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return result.user;
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> signUpWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return result.user;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // --- USER PROFILE METHODS ---
  Future<void> createUserDocument(User user, String username, String avatarUrl) async {
    final userDoc = _firestore.collection('users').doc(user.uid);
    final doc = await userDoc.get();
    
    if (doc.exists) {
      // If document exists, only update specified fields to preserve following/followers
      await userDoc.update({
        'username': username,
        'email': user.email!,
        'avatarUrl': avatarUrl,
      });
    } else {
      // If it's a new user, create the document with initial empty lists
      final newUser = UserModel(
        id: user.uid, 
        username: username, 
        email: user.email!, 
        avatarUrl: avatarUrl,
        bookmarks: [],
        followers: [],
        following: [],
      );
      await userDoc.set(newUser.toMap());
    }
  }

  Stream<UserModel> getUserProfile(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((doc) => UserModel.fromFirestore(doc));
  }

  Future<List<UserModel>> getUsersByIds(List<String> userIds) async {
    if (userIds.isEmpty) return [];
    // Firestore whereIn limit is 10, for larger lists you'd need to batch.
    final snapshot = await _firestore.collection('users').where(FieldPath.documentId, whereIn: userIds).get();
    return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
  }

  Future<void> followUser(String currentUserId, String targetUserId) async {
    await _firestore.collection('users').doc(currentUserId).update({'following': FieldValue.arrayUnion([targetUserId])});
    await _firestore.collection('users').doc(targetUserId).update({'followers': FieldValue.arrayUnion([currentUserId])});
    
    final currentUserDoc = await _firestore.collection('users').doc(currentUserId).get();
    final currentUser = UserModel.fromFirestore(currentUserDoc);

    final notification = NotificationModel(
      id: '',
      fromUserId: currentUserId,
      fromUsername: currentUser.username,
      fromUserAvatar: currentUser.avatarUrl,
      toUserId: targetUserId,
      type: NotificationType.follow,
      timestamp: DateTime.now(),
    );

    await _firestore.collection('notifications').add(notification.toMap());
  }

  Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    await _firestore.collection('users').doc(currentUserId).update({'following': FieldValue.arrayRemove([targetUserId])});
    await _firestore.collection('users').doc(targetUserId).update({'followers': FieldValue.arrayRemove([currentUserId])});
  }

  Future<void> toggleBookmark(String userId, String postId) async {
    final userDoc = _firestore.collection('users').doc(userId);
    final doc = await userDoc.get();
    if (!doc.exists) return;
    
    List<String> bookmarks = List<String>.from(doc.data()?['bookmarks'] ?? []);
    if (bookmarks.contains(postId)) {
      bookmarks.remove(postId);
    } else {
      bookmarks.add(postId);
    }
    await userDoc.update({'bookmarks': bookmarks});
  }

  Future<List<UserModel>> searchUsers(String query) async {
    if (query.isEmpty) return [];
    final snapshot = await _firestore
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThanOrEqualTo: '$query\uf8ff')
        .get();
    return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
  }

  // --- NOTIFICATION METHODS ---

  Stream<List<NotificationModel>> getNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('toUserId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final notifications = snapshot.docs.map((doc) => NotificationModel.fromFirestore(doc)).toList();
          notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return notifications;
        });
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({'isRead': true});
  }

  // --- CHAT METHODS ---

  String getChatId(String user1, String user2) {
    List<String> ids = [user1, user2];
    ids.sort(); 
    return ids.join('_');
  }

  Future<void> sendMessage(MessageModel message) async {
    await _firestore.collection('messages').add(message.toMap());
  }

  Stream<List<MessageModel>> getMessages(String userId, String otherUserId) {
    final chatId = getChatId(userId, otherUserId);
    return _firestore
        .collection('messages')
        .where('chatId', isEqualTo: chatId)
        .snapshots()
        .map((snapshot) {
          final messages = snapshot.docs
              .map((doc) => MessageModel.fromFirestore(doc))
              .toList();
          messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return messages;
        });
  }

  Stream<List<MessageModel>> getUnreadMessages(String userId) {
    return _firestore
        .collection('messages')
        .where('receiverId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => MessageModel.fromFirestore(doc)).toList());
  }

  Future<void> markMessagesAsRead(String userId, String otherUserId) async {
    final chatId = getChatId(userId, otherUserId);
    final snapshot = await _firestore
        .collection('messages')
        .where('chatId', isEqualTo: chatId)
        .where('receiverId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
    
    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Stream<List<UserModel>> getChatUsers(String currentUserId) {
    return _firestore.collection('users').doc(currentUserId).snapshots().asyncMap((userDoc) async {
      final user = UserModel.fromFirestore(userDoc);
      final chatUserIds = {...user.following, ...user.followers}.toList();
      if (chatUserIds.isEmpty) return [];
      
      final usersSnapshot = await _firestore.collection('users').where(FieldPath.documentId, whereIn: chatUserIds).get();
      return usersSnapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    });
  }

  // --- DATA FETCHING METHODS ---

  Stream<List<PostModel>> getPosts() {
    return _firestore
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList();
    });
  }

  Stream<List<StoryModel>> getStories() {
    return _firestore
        .collection('stories')
        .where('timestamp', isGreaterThan: Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 24))))
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => StoryModel.fromFirestore(doc)).toList();
    });
  }

  // --- DATA CREATION/DELETION METHODS ---

  Future<void> addPost(PostModel post) async {
    await _firestore.collection('posts').doc(post.id).set(post.toMap());
  }

  Future<void> deletePost(String postId) async {
    await _firestore.collection('posts').doc(postId).delete();
  }

  Future<void> likePost(String postId, String userId) async {
    final postRef = _firestore.collection('posts').doc(postId);
    await _firestore.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(postRef);
      if (!snapshot.exists) return;
      List<String> likedBy = List<String>.from(snapshot['likedBy'] ?? []);
      likedBy.contains(userId) ? likedBy.remove(userId) : likedBy.add(userId);
      transaction.update(postRef, {'likedBy': likedBy, 'likes': likedBy.length});
    });
  }

  Future<void> addComment(String postId, CommentModel comment) async {
    await _firestore.collection('posts').doc(postId).collection('comments').add(comment.toMap());
  }

  Stream<List<CommentModel>> getComments(String postId) {
    return _firestore.collection('posts').doc(postId).collection('comments').orderBy('timestamp', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => CommentModel.fromFirestore(doc)).toList();
    });
  }

  Future<void> addStory(StoryModel story) async {
    await _firestore.collection('stories').doc(story.id).set(story.toMap());
  }

  Future<void> deleteStory(String storyId) async {
    await _firestore.collection('stories').doc(storyId).delete();
  }
}
