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
    final data = doc.data() as Map<String, dynamic>;
    return GroupSubscriptionModel(
      id: doc.id,
      name: data['groupName'] ?? 'Unnamed Group',
      subscribedAt: data['subscribedAt']?.toDate() ?? DateTime.now(),
    );
  }
}