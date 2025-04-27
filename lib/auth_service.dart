import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  // Get current user ID, now using FCM token as the primary identifier
  Future<String> getUserId() async {
    // Try to use FCM token first
    String? fcmToken = await _messaging.getToken();
    if (fcmToken != null && fcmToken.isNotEmpty) {
      debugPrint('Using FCM token as user ID: ${fcmToken.substring(0, 10)}...');
      
      // Store the token in SharedPreferences for persistence
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', fcmToken);
      
      return fcmToken;
    }

    // If we already have a signed-in user, use that
    if (_auth.currentUser != null) {
      return _auth.currentUser!.uid;
    }

    // Try to retrieve previously stored user ID from SharedPreferences
    final storedId = await _getStoredUserId();
    if (storedId != null) {
      return storedId;
    }

    // As a last resort, generate and store a device-specific ID
    return _generateDeviceId();
  }

  // Retrieve previously stored user ID
  Future<String?> _getStoredUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('user_id');
      
      if (userId != null && userId.isNotEmpty) {
        debugPrint('Retrieved stored user ID: ${userId.substring(0, 10)}...');
        return userId;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting stored user ID: $e');
      return null;
    }
  }

  // Generate a unique device ID as a fallback
  Future<String> _generateDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String deviceId = DateTime.now().millisecondsSinceEpoch.toString() +
          '_${UniqueKey().toString()}';
      
      await prefs.setString('user_id', deviceId);
      debugPrint('Generated new device ID: ${deviceId.substring(0, 10)}...');
      return deviceId;
    } catch (e) {
      // Last resort fallback
      debugPrint('Error generating device ID: $e');
      return 'device_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  // Check if we have a valid user ID
  Future<bool> get hasUserId async {
    final id = await getUserId();
    return id.isNotEmpty;
  }
}