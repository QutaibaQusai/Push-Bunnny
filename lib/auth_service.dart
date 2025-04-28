import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  
  // Static UUID generator
  static const Uuid _uuid = Uuid();
  
  // Key for storing user ID in SharedPreferences
  static const String _userIdKey = 'persistent_user_id';
  
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  // Get current user ID, using a persistent UUID stored in SharedPreferences
  Future<String> getUserId() async {
    // First, try to get the UUID from SharedPreferences
    final persistentId = await _getPersistentUserId();
    if (persistentId != null) {
      debugPrint('Using persistent UUID as user ID: ${persistentId.substring(0, 10)}...');
      return persistentId;
    }
    
    // If no persistent ID exists, generate a new one and store it
    final newUuid = _generateAndStorePersistentUserId();
    return newUuid;
  }

  // Retrieve previously stored persistent user ID
  Future<String?> _getPersistentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString(_userIdKey);
      
      if (userId != null && userId.isNotEmpty) {
        debugPrint('Retrieved persistent user ID: ${userId.substring(0, 10)}...');
        return userId;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting persistent user ID: $e');
      return null;
    }
  }

  // Generate a new UUID and store it in SharedPreferences
  Future<String> _generateAndStorePersistentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String newUserId = _uuid.v4(); // Generate a UUID v4
      
      await prefs.setString(_userIdKey, newUserId);
      debugPrint('Generated new persistent user ID: ${newUserId.substring(0, 10)}...');
      return newUserId;
    } catch (e) {
      // Last resort fallback
      debugPrint('Error generating persistent user ID: $e');
      final fallbackId = 'device_${DateTime.now().millisecondsSinceEpoch}';
      return fallbackId;
    }
  }

  // Check if we have a valid user ID
  Future<bool> get hasUserId async {
    final id = await getUserId();
    return id.isNotEmpty;
  }
}