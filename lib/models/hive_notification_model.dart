import 'package:hive/hive.dart';
import 'package:push_bunnny/models/notification_model.dart';
// Add this line at the top of the file
part 'hive_notification_model.g.dart';


@HiveType(typeId: 0)
class HiveNotificationModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final String body;

  @HiveField(4)
  final DateTime timestamp;

  @HiveField(5)
  final String? imageUrl;

  @HiveField(6)
  final String? groupId;

  @HiveField(7)
  final String? groupName;

  @HiveField(8)
  bool isRead;

  @HiveField(9)
  DateTime? readAt;

  @HiveField(10)
  final bool isSynced; // Track if the notification is synced with Firestore

  HiveNotificationModel({
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
    this.isSynced = true, // Default is true for notifications from Firestore
  });

  // Create from Firestore NotificationModel
  factory HiveNotificationModel.fromNotificationModel(
      NotificationModel notification) {
    return HiveNotificationModel(
      id: notification.id,
      userId: notification.userId,
      title: notification.title,
      body: notification.body,
      timestamp: notification.timestamp,
      imageUrl: notification.imageUrl,
      groupId: notification.groupId,
      groupName: notification.groupName,
      isRead: notification.isRead,
      readAt: notification.readAt,
      isSynced: true,
    );
  }

  // Convert to NotificationModel
  NotificationModel toNotificationModel() {
    return NotificationModel(
      id: id,
      userId: userId,
      title: title,
      body: body,
      timestamp: timestamp,
      imageUrl: imageUrl,
      groupId: groupId,
      groupName: groupName,
      isRead: isRead,
      readAt: readAt,
    );
  }
}