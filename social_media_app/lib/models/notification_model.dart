import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType { follow, like, comment }

class NotificationModel {
  final String id;
  final String fromUserId;
  final String fromUsername;
  final String fromUserAvatar;
  final String toUserId;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.fromUserId,
    required this.fromUsername,
    required this.fromUserAvatar,
    required this.toUserId,
    required this.type,
    required this.timestamp,
    this.isRead = false,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      fromUserId: data['fromUserId'] ?? '',
      fromUsername: data['fromUsername'] ?? '',
      fromUserAvatar: data['fromUserAvatar'] ?? '',
      toUserId: data['toUserId'] ?? '',
      type: NotificationType.values.firstWhere((e) => e.toString() == data['type']),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fromUserId': fromUserId,
      'fromUsername': fromUsername,
      'fromUserAvatar': fromUserAvatar,
      'toUserId': toUserId,
      'type': type.toString(),
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
    };
  }
}
