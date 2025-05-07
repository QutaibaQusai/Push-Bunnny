import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:push_bunnny/core/services/local_storage_service.dart';
import 'package:push_bunnny/core/utils/connectivity_helper.dart';

import 'package:uuid/uuid.dart';
import 'dart:io';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final LocalStorageService _storage = LocalStorageService();
  final ConnectivityHelper _connectivity = ConnectivityHelper();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  
  static const Uuid _uuid = Uuid();
  
  String? _userId;
  String? get userId => _userId;

  Future<void> initialize() async {
    await _storage.initialize();
    _connectivity.initialize();
    await _ensureUserId();
    await _registerDevice();
  }

  Future<void> _ensureUserId() async {
    // First check if we already have the ID in memory
    if (_userId != null) return;
    
    // Then try to get from local storage
    _userId = _storage.getUserId();
    
    if (_userId == null) {
      // Generate a new ID if none exists
      _userId = _uuid.v4();
      await _storage.saveUserId(_userId!);
      
      debugPrint('Generated new user ID: $_userId');
    } else {
      debugPrint('Retrieved existing user ID: $_userId');
    }
  }

  Future<void> _registerDevice() async {
    if (_userId == null) {
      await _ensureUserId();
    }
    
    try {
      final token = await _messaging.getToken();
      final deviceInfoData = await _getDeviceInfo();
      
      if (token != null && _connectivity.isOnline) {
        await _firestore.collection('users').doc(_userId).set({
          'deviceToken': token,
          'deviceInfo': deviceInfoData,
          'lastActive': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        debugPrint('Device registered with token: ${token.substring(0, 10)}...');
      }
      
      // Set up token refresh listener
      _messaging.onTokenRefresh.listen((newToken) async {
        await updateDeviceToken(newToken);
      });
    } catch (e) {
      debugPrint('Error registering device: $e');
    }
  }

  Future<void> updateDeviceToken(String token) async {
    try {
      if (_userId != null && _connectivity.isOnline) {
        await _firestore.collection('users').doc(_userId).update({
          'deviceToken': token,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        debugPrint('Device token updated: ${token.substring(0, 10)}...');
      }
    } catch (e) {
      debugPrint('Error updating device token: $e');
    }
  }

  Future<Map<String, dynamic>> _getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        return _getAndroidDeviceInfo();
      } else if (Platform.isIOS) {
        return _getIosDeviceInfo();
      } else {
        return {
          'platform': defaultTargetPlatform.toString(),
          'unknown': true,
        };
      }
    } catch (e) {
      debugPrint('Error getting device info: $e');
      return {
        'error': 'Failed to get device info: $e',
      };
    }
  }

  Future<Map<String, dynamic>> _getAndroidDeviceInfo() async {
    final AndroidDeviceInfo info = await _deviceInfo.androidInfo;
    
    return {
      'platform': 'android',
      'model': info.model,
      'manufacturer': info.manufacturer,
      'androidVersion': info.version.release,
      'sdkInt': info.version.sdkInt,
      'isPhysicalDevice': info.isPhysicalDevice,
    };
  }

  Future<Map<String, dynamic>> _getIosDeviceInfo() async {
    final IosDeviceInfo info = await _deviceInfo.iosInfo;
    
    return {
      'platform': 'ios',
      'model': info.model,
      'name': info.name,
      'systemName': info.systemName,
      'systemVersion': info.systemVersion,
      'isPhysicalDevice': info.isPhysicalDevice,
    };
  }

  Future<void> updateLastActive() async {
    if (_userId == null || !_connectivity.isOnline) return;
    
    try {
      await _firestore.collection('users').doc(_userId).update({
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating last active: $e');
    }
  }
}