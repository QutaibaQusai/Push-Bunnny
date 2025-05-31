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
      subscribedAt: map['subscribedAt'] is String 
          ? DateTime.parse(map['subscribedAt'])
          : map['subscribedAt'] ?? DateTime.now(),
    );
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