import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  // Get current user ID, ensuring we always have one
  Future<String> getUserId() async {
    if (_auth.currentUser != null) {
      return _auth.currentUser!.uid;
    }

    // Try to sign in anonymously
    try {
      final userCredential = await _auth.signInAnonymously();
      debugPrint(
        'Anonymous auth successful with user ID: ${userCredential.user!.uid}',
      );
      return userCredential.user!.uid;
    } catch (e) {
      debugPrint('Error signing in anonymously: $e');

      // As a fallback, generate and store a device-specific ID
      return _getDeviceId();
    }
  }

  // Fallback method to get a persistent device ID if Firebase auth fails
  Future<String> _getDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? deviceId = prefs.getString('device_id');

      if (deviceId == null) {
        // Generate a simple unique ID (you could use a more sophisticated approach)
        deviceId =
            DateTime.now().millisecondsSinceEpoch.toString() +
            '_${UniqueKey().toString()}';
        await prefs.setString('device_id', deviceId);
      }

      debugPrint('Using device ID: $deviceId');
      return deviceId;
    } catch (e) {
      // Last resort fallback
      debugPrint('Error getting device ID: $e');
      return 'anonymous_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  // Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null;
}
