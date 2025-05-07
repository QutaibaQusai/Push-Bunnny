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
  final Map<String, dynamic>? data;
  final String? messageId;

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
    this.data,
    this.messageId,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      return NotificationModel(
        id: doc.id,
        userId: '',
        title: 'Unknown Notification',
        body: '',
        timestamp: DateTime.now(),
      );
    }

    // Handle Firestore timestamp properly
    DateTime timestamp;
    if (data['timestamp'] is Timestamp) {
      timestamp = (data['timestamp'] as Timestamp).toDate();
    } else if (data['timestamp'] != null) {
      timestamp = DateTime.parse(data['timestamp'].toString());
    } else {
      timestamp = DateTime.now();
    }

    // Handle readAt timestamp
    DateTime? readAt;
    if (data['readAt'] is Timestamp) {
      readAt = (data['readAt'] as Timestamp).toDate();
    } else if (data['readAt'] != null) {
      readAt = DateTime.parse(data['readAt'].toString());
    }

    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? 'Notification',
      body: data['body'] ?? '',
      timestamp: timestamp,
      imageUrl: data['imageUrl'],
      groupId: data['groupId'],
      groupName: data['groupName'],
      isRead: data['isRead'] ?? false,
      readAt: readAt,
      data: Map<String, dynamic>.from(data),
      messageId: data['messageId'],
    );
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    // Handle timestamp from Hive
    DateTime timestamp;
    if (map['timestamp'] is String) {
      timestamp = DateTime.parse(map['timestamp']);
    } else if (map['timestamp'] is DateTime) {
      timestamp = map['timestamp'];
    } else {
      timestamp = DateTime.now();
    }

    // Handle readAt from Hive
    DateTime? readAt;
    if (map['readAt'] is String && map['readAt'] != null) {
      readAt = DateTime.parse(map['readAt']);
    } else if (map['readAt'] is DateTime) {
      readAt = map['readAt'];
    }

    return NotificationModel(
      id: map['id'],
      userId: map['userId'] ?? '',
      title: map['title'] ?? 'Notification',
      body: map['body'] ?? '',
      timestamp: timestamp,
      imageUrl: map['imageUrl'],
      groupId: map['groupId'],
      groupName: map['groupName'],
      isRead: map['isRead'] ?? false,
      readAt: readAt,
      data: map['data'],
      messageId: map['messageId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'body': body,
      'timestamp': timestamp.toIso8601String(), // Store as ISO string for Hive
      'imageUrl': imageUrl,
      'groupId': groupId,
      'groupName': groupName,
      'isRead': isRead,
      'readAt': readAt?.toIso8601String(),
      'data': data,
      'messageId': messageId,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    DateTime? timestamp,
    String? imageUrl,
    String? groupId,
    String? groupName,
    bool? isRead,
    DateTime? readAt,
    Map<String, dynamic>? data,
    String? messageId,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      timestamp: timestamp ?? this.timestamp,
      imageUrl: imageUrl ?? this.imageUrl,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      data: data ?? this.data,
      messageId: messageId ?? this.messageId,
    );
  }
}
