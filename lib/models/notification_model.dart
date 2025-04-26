import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final DateTime timestamp;
  final String? imageUrl;
  final String? groupId;
  final String? groupName;
  final bool isRead;
  final DateTime? readAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.timestamp,
    this.imageUrl,
    this.groupId,
    this.groupName,
    this.isRead = false,
    this.readAt,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? 'anonymous',
      title: data['title'] ?? 'Notification',
      body: data['body'] ?? '',
      timestamp: data['timestamp']?.toDate() ?? DateTime.now(),
      imageUrl: data['imageUrl'],
      groupId: data['groupId'],
      groupName: data['groupName'],
      isRead: data['isRead'] ?? false,
      readAt: data['readAt']?.toDate(),
    );
  }
}