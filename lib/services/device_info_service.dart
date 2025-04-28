import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

class DeviceInfoService {
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();
  
  // Singleton pattern
  static final DeviceInfoService _instance = DeviceInfoService._internal();

  factory DeviceInfoService() {
    return _instance;
  }

  DeviceInfoService._internal();

  // Get device information as a Map
  Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        return await _getAndroidDeviceInfo();
      } else if (Platform.isIOS) {
        return await _getIosDeviceInfo();
      } else {
        return {
          'deviceModel': 'Unknown',
          'manufacturer': 'Unknown',
          'platform': 'Unknown',
          'osVersion': 'Unknown',
          'isPhysicalDevice': false,
        };
      }
    } catch (e) {
      debugPrint('Error getting device info: $e');
      return {
        'deviceModel': 'Error',
        'manufacturer': 'Error',
        'platform': 'Error',
        'osVersion': 'Error',
        'isPhysicalDevice': false,
      };
    }
  }

  Future<Map<String, dynamic>> _getAndroidDeviceInfo() async {
    final AndroidDeviceInfo info = await _deviceInfoPlugin.androidInfo;
    
    return {
      'deviceModel': info.model,
      'manufacturer': info.manufacturer,
      'platform': 'Android',
      'osVersion': info.version.release,
      'isPhysicalDevice': info.isPhysicalDevice ?? false,
    };
  }

  Future<Map<String, dynamic>> _getIosDeviceInfo() async {
    final IosDeviceInfo info = await _deviceInfoPlugin.iosInfo;
    
    return {
      'deviceModel': info.model ?? info.name ?? 'iOS Device',
      'manufacturer': 'Apple',
      'platform': 'iOS',
      'osVersion': info.systemVersion ?? 'Unknown',
      'isPhysicalDevice': info.isPhysicalDevice,
    };
  }
}