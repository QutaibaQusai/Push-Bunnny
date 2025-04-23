import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:push_bunnny/models/group.dart';

class GroupRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> subscribeToGroup(String groupId, String userId) async {
    await _firestore.collection('groups').doc(groupId).update({
      'subscriberIds': FieldValue.arrayUnion([userId]),
    });
  }

  Future<void> unsubscribeFromGroup(String groupId, String userId) async {
    await _firestore.collection('groups').doc(groupId).update({
      'subscriberIds': FieldValue.arrayRemove([userId]),
    });
  }

  Stream<List<Group>> getUserGroups(String userId) {
    return _firestore
        .collection('groups')
        .where('subscriberIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Group.fromFirestore).toList());
  }

  Stream<List<Group>> getAllGroups() {
    return _firestore
        .collection('groups')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Group.fromFirestore).toList());
  }
}
