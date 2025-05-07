import 'package:cloud_firestore/cloud_firestore.dart';

class GroupSubscriptionModel {
  final String id;
  final String name;
  final DateTime subscribedAt;

  GroupSubscriptionModel({
    required this.id,
    required this.name,
    required this.subscribedAt,
  });

  factory GroupSubscriptionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    
    if (data == null) {
      return GroupSubscriptionModel(
        id: doc.id,
        name: 'Unknown Group',
        subscribedAt: DateTime.now(),
      );
    }
    
    return GroupSubscriptionModel(
      id: doc.id,
      name: data['groupName'] ?? doc.id,
      subscribedAt: data['subscribedAt']?.toDate() ?? DateTime.now(),
    );
  }

  factory GroupSubscriptionModel.fromMap(Map<String, dynamic> map) {
    return GroupSubscriptionModel(
      id: map['id'],
      name: map['name'],
      subscribedAt: DateTime.parse(map['subscribedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'subscribedAt': subscribedAt.toIso8601String(),
    };
  }
}