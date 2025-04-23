import 'package:cloud_firestore/cloud_firestore.dart';

class Group {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final List<String> subscriberIds;

  Group({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.subscriberIds,
  });

  factory Group.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Group(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'],
      imageUrl: data['imageUrl'],
      subscriberIds: List<String>.from(data['subscriberIds'] ?? []),
    );
  }
}