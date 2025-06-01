class GroupModel {
  final String id;
  final String userId;
  final String name;
  final DateTime subscribedAt;

  GroupModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.subscribedAt,
  });

  factory GroupModel.fromMap(Map<String, dynamic> map) {
    return GroupModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      subscribedAt: _parseDateTime(map['subscribedAt']) ?? DateTime.now(),
    );
  }

  // Helper method to parse different date formats
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    
    if (value is DateTime) {
      return value;
    } else if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('❌ Failed to parse DateTime from string: $value');
        return DateTime.now();
      }
    } else if (value.runtimeType.toString() == 'Timestamp') {
      // Handle Firestore Timestamp
      try {
        return (value as dynamic).toDate();
      } catch (e) {
        print('❌ Failed to convert Timestamp to DateTime: $e');
        return DateTime.now();
      }
    }
    
    print('❌ Unknown timestamp type: ${value.runtimeType}');
    return DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'subscribedAt': subscribedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'GroupModel(id: $id, name: $name, userId: $userId)';
  }
}