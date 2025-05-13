import Flutter
import UIKit

class NotificationPlugin: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "com.example.push_bunnny/notifications", binaryMessenger: registrar.messenger())
    let instance = NotificationPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }
  
  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getStoredNotification":
      if let lastTime = UserDefaults.standard.object(forKey: "lastNotificationTime") as? TimeInterval {
        // Only return notifications received in the last 30 seconds
        let currentTime = Date().timeIntervalSince1970
        if currentTime - lastTime < 30 {
          // Find the most recent notification
          var latestNotification: [AnyHashable: Any]? = nil
          var latestKey: String? = nil
          
          for key in UserDefaults.standard.dictionaryRepresentation().keys {
            if key.starts(with: "bgNotification_"), 
               let notification = UserDefaults.standard.dictionary(forKey: key) {
              latestNotification = notification
              latestKey = key
              break
            }
          }
          
          if let notification = latestNotification {
            result(notification)
            return
          }
        }
      }
      result(nil)
      
    case "clearStoredNotification":
      // Clear any stored notifications
      for key in UserDefaults.standard.dictionaryRepresentation().keys {
        if key.starts(with: "bgNotification_") {
          UserDefaults.standard.removeObject(forKey: key)
        }
      }
      UserDefaults.standard.removeObject(forKey: "lastNotificationTime")
      result(nil)
      
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}