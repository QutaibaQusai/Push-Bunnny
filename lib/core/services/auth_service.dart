import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:push_bunnny/core/services/storage_service.dart';
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
    // Try to get from storage first
    _userId = await StorageService.instance.getUserId();
    
    if (_userId == null) {
      // Generate new UUID
      _userId = _uuid.v4();
      await StorageService.instance.saveUserId(_userId!);
      debugPrint('📱 Generated new user ID: $_userId');
    } else {
      debugPrint('📱 Retrieved existing user ID: $_userId');
    }
  }

  Future<void> _registerDevice() async {
    try {
      final token = await _messaging.getToken();
      final deviceInfo = await _getDeviceInfo();
      
      if (token != null) {
        await _firestore.collection('users').doc(_userId).set({
          'deviceToken': token,
          'deviceInfo': deviceInfo,
          'lastActive': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
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
}