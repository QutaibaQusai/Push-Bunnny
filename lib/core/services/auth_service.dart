import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class AuthService {
  static final AuthService instance = AuthService._();
  AuthService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final Uuid _uuid = const Uuid();

  String? _userId;
  String? get userId => _userId;

  Future<void> initialize() async {
    await _ensureUserId();
    await _registerDevice();
  }

  Future<void> _ensureUserId() async {
    // Try to get from SharedPreferences first (lightweight local storage)
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('userId');
    
    if (_userId == null) {
      // Generate new UUID
      _userId = _uuid.v4();
      await prefs.setString('userId', _userId!);
      debugPrint('📱 Generated new user ID: $_userId');
      
      // Create user document in Firestore
      await _createUserDocument();
    } else {
      debugPrint('📱 Retrieved existing user ID: $_userId');
    }
  }

  Future<void> _createUserDocument() async {
    try {
      await _firestore.collection('users').doc(_userId).set({
        'createdAt': FieldValue.serverTimestamp(),
        'lastActive': FieldValue.serverTimestamp(),
        'deviceInfo': await _getDeviceInfo(),
      });
      debugPrint('✅ User document created');
    } catch (e) {
      debugPrint('❌ Failed to create user document: $e');
    }
  }

  Future<void> _registerDevice() async {
    try {
      final token = await _messaging.getToken();
      final deviceInfo = await _getDeviceInfo();
      
      if (token != null) {
        await _firestore.collection('users').doc(_userId).update({
          'deviceToken': token,
          'deviceInfo': deviceInfo,
          'lastActive': FieldValue.serverTimestamp(),
        });
        
        debugPrint('✅ Device registered successfully');
      }
      
      // Listen for token refresh
      _messaging.onTokenRefresh.listen(_updateToken);
    } catch (e) {
      debugPrint('❌ Device registration failed: $e');
    }
  }

  Future<void> _updateToken(String newToken) async {
    try {
      await _firestore.collection('users').doc(_userId).update({
        'deviceToken': newToken,
        'lastActive': FieldValue.serverTimestamp(),
      });
      debugPrint('🔄 Token updated successfully');
    } catch (e) {
      debugPrint('❌ Token update failed: $e');
    }
  }

  Future<Map<String, dynamic>> _getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        return {
          'platform': 'android',
          'model': info.model,
          'manufacturer': info.manufacturer,
          'version': info.version.release,
          'sdkInt': info.version.sdkInt,
        };
      } else if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        return {
          'platform': 'ios',
          'model': info.model,
          'name': info.name,
          'systemName': info.systemName,
          'systemVersion': info.systemVersion,
        };
      }
      return {'platform': 'unknown'};
    } catch (e) {
      debugPrint('❌ Failed to get device info: $e');
      return {'platform': 'unknown', 'error': e.toString()};
    }
  }

  Future<void> updateLastActive() async {
    try {
      await _firestore.collection('users').doc(_userId).update({
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('❌ Failed to update last active: $e');
    }
  }

  // Clear user data (for logout/reset functionality)
  Future<void> clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('userId');
      _userId = null;
      debugPrint('🗑️ User data cleared');
    } catch (e) {
      debugPrint('❌ Failed to clear user data: $e');
    }
  }
}