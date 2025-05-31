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
    try {
      // Multiple attempts to get SharedPreferences with delays
      SharedPreferences? prefs;
      int attempts = 0;
      const maxAttempts = 3;

      while (prefs == null && attempts < maxAttempts) {
        try {
          prefs = await SharedPreferences.getInstance();
          break;
        } catch (e) {
          attempts++;
          debugPrint('❌ SharedPreferences attempt $attempts failed: $e');
          if (attempts < maxAttempts) {
            await Future.delayed(Duration(milliseconds: 100 * attempts));
          }
        }
      }

      if (prefs == null) {
        throw Exception(
          'Failed to initialize SharedPreferences after $maxAttempts attempts',
        );
      }

      // Try to get existing user ID with fallback
      _userId = prefs.getString('userId');

      // Additional verification - check if the value was actually persisted
      if (_userId != null) {
        // Verify the user ID is valid (UUID format)
        if (_userId!.length != 36 || !_userId!.contains('-')) {
          debugPrint('⚠️ Invalid user ID format found, generating new one');
          _userId = null;
        } else {
          debugPrint('📱 Retrieved existing user ID: $_userId');
        }
      }

      if (_userId == null) {
        // Generate new UUID
        _userId = _uuid.v4();
        debugPrint('📱 Generated new user ID: $_userId');

        // Save with multiple verification attempts
        bool saved = false;
        for (int i = 0; i < 3; i++) {
          try {
            await prefs.setString('userId', _userId!);

            // Verify it was actually saved
            final savedValue = prefs.getString('userId');
            if (savedValue == _userId) {
              saved = true;
              debugPrint('✅ User ID saved and verified: $_userId');
              break;
            } else {
              debugPrint(
                '⚠️ User ID save verification failed, attempt ${i + 1}',
              );
            }
          } catch (e) {
            debugPrint('❌ Failed to save user ID, attempt ${i + 1}: $e');
          }

          if (!saved && i < 2) {
            await Future.delayed(Duration(milliseconds: 200));
          }
        }

        if (!saved) {
          debugPrint('❌ Failed to save user ID after multiple attempts');
        }

        // Create user document in Firestore
        await _createUserDocument();
      }
    } catch (e) {
      debugPrint('❌ Critical error in _ensureUserId: $e');
      // Fallback: generate a temporary user ID for this session
      _userId = _uuid.v4();
      debugPrint('🔄 Using temporary user ID for this session: $_userId');
    }
  }

  Future<void> _createUserDocument() async {
    try {
      if (_userId == null) return;

      // Check if user document already exists
      final userDoc = await _firestore.collection('users').doc(_userId).get();

      if (!userDoc.exists) {
        await _firestore.collection('users').doc(_userId).set({
          'createdAt': FieldValue.serverTimestamp(),
          'lastActive': FieldValue.serverTimestamp(),
          'deviceInfo': await _getDeviceInfo(),
        });
        debugPrint('✅ User document created');
      } else {
        // Update last active
        await _firestore.collection('users').doc(_userId).update({
          'lastActive': FieldValue.serverTimestamp(),
        });
        debugPrint('✅ User document updated');
      }
    } catch (e) {
      debugPrint('❌ Failed to create/update user document: $e');
    }
  }

  Future<void> _registerDevice() async {
    try {
      final token = await _messaging.getToken();
      final deviceInfo = await _getDeviceInfo();

      if (token != null && _userId != null) {
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
      if (_userId != null) {
        await _firestore.collection('users').doc(_userId).update({
          'deviceToken': newToken,
          'lastActive': FieldValue.serverTimestamp(),
        });
        debugPrint('🔄 Token updated successfully');
      }
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
          'fingerprint': info.fingerprint, // More unique identifier
        };
      } else if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        return {
          'platform': 'ios',
          'model': info.model,
          'name': info.name,
          'systemName': info.systemName,
          'systemVersion': info.systemVersion,
          'identifierForVendor':
              info.identifierForVendor, // More unique identifier
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
      if (_userId != null) {
        await _firestore.collection('users').doc(_userId).update({
          'lastActive': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('❌ Failed to update last active: $e');
    }
  }

  // Clear user data (for logout/reset functionality)
  Future<void> clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('userId');
      await prefs.clear(); // Clear all preferences
      _userId = null;
      debugPrint('🗑️ User data cleared');
    } catch (e) {
      debugPrint('❌ Failed to clear user data: $e');
    }
  }

  // Debug method to check SharedPreferences status
  Future<void> debugSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedUserId = prefs.getString('userId');
      final allKeys = prefs.getKeys();

      debugPrint('🔍 SharedPreferences Debug:');
      debugPrint('  - Stored userId: $storedUserId');
      debugPrint('  - Current userId: $_userId');
      debugPrint('  - All keys: $allKeys');
      debugPrint('  - Keys count: ${allKeys.length}');
    } catch (e) {
      debugPrint('❌ Failed to debug SharedPreferences: $e');
    }
  }
}
