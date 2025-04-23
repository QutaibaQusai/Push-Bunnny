import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Stream<QuerySnapshot> getUserNotifications() {
    final userId = _auth.currentUser?.uid ?? 'anonymous';
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }

  Future<void> deleteNotification(String docId) async {
    await _firestore.collection('notifications').doc(docId).delete();
  }
}
