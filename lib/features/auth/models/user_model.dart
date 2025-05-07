import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String? deviceToken;
  final Map<String, dynamic>? deviceInfo;
  final DateTime? createdAt;
  final DateTime? lastActive;

  const UserModel({
    required this.id,
    this.deviceToken,
    this.deviceInfo,
    this.createdAt,
    this.lastActive,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    
    if (data == null) {
      return UserModel(id: doc.id);
    }
    
    return UserModel(
      id: doc.id,
      deviceToken: data['deviceToken'],
      deviceInfo: data['deviceInfo'] as Map<String, dynamic>?,
      createdAt: data['createdAt']?.toDate(),
      lastActive: data['lastActive']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deviceToken': deviceToken,
      'deviceInfo': deviceInfo,
      'createdAt': createdAt,
      'lastActive': lastActive,
    };
  }
}