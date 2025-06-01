class NotificationModel {
  final String id;
  final String userId;
  final String messageId;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;
  final DateTime? readAt;
  final String appState; // foreground, background, terminated
  final Map<String, dynamic> data;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.messageId,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    this.readAt,
    required this.appState,
    this.data = const {},
  });

  // Getters for new data structure
  String? get type => data['type']; // 'user' or 'group'
  String? get targetId => data['id']; // user_id or group_id
  String? get imageUrl => data['image'];
  String? get link => data['link'];
  
  // For backward compatibility and UI display
  String? get groupId => type == 'group' ? targetId : null;
  String? get groupName => type == 'group' ? targetId : null;
  bool get isGroupNotification => type == 'group';
  bool get isUserNotification => type == 'user';

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      messageId: map['messageId'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      timestamp: _parseDateTime(map['timestamp']) ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
      readAt: _parseDateTime(map['readAt']),
      appState: map['appState'] ?? 'unknown',
      data: Map<String, dynamic>.from(map['data'] ?? {}),
    );
  }

  // Helper method to parse different date formats
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    
    if (value is DateTime) {
      return value;
    } else if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('❌ Failed to parse DateTime from string: $value');
        return null;
      }
    } else if (value.runtimeType.toString() == 'Timestamp') {
      // Handle Firestore Timestamp
      try {
        return (value as dynamic).toDate();
      } catch (e) {
        print('❌ Failed to convert Timestamp to DateTime: $e');
        return null;
      }
    }
    
    print('❌ Unknown timestamp type: ${value.runtimeType}');
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'messageId': messageId,
      'title': title,
      'body': body,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'readAt': readAt?.toIso8601String(),
      'appState': appState,
      'data': data,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? messageId,
    String? title,
    String? body,
    DateTime? timestamp,
    bool? isRead,
    DateTime? readAt,
    String? appState,
    Map<String, dynamic>? data,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      messageId: messageId ?? this.messageId,
      title: title ?? this.title,
      body: body ?? this.body,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      appState: appState ?? this.appState,
      data: data ?? this.data,
    );
  }

  @override
  String toString() {
    return 'NotificationModel(id: $id, title: $title, type: $type, targetId: $targetId)';
  }
}