import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
    private var methodChannel: FlutterMethodChannel?
    private let groupIdentifier = "group.id.bee.sharemanual"
    private let sharedKey = "ShareKey"
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller = window?.rootViewController as! FlutterViewController
        
        methodChannel = FlutterMethodChannel(
            name: "id.bee.sharemanual/share",
            binaryMessenger: controller.binaryMessenger
        )
        
        methodChannel?.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else { return }
            
            switch call.method {
            case "getInitialShare":
                let sharedData = self.getSharedData()
                result(sharedData)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    override func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        // Handle URL from Share Extension
        if url.scheme == "ShareManualApp" {
            if let sharedData = getSharedData() {
                // Send to Flutter
                methodChannel?.invokeMethod("onShareReceived", arguments: sharedData)
            }
        }
        return true
    }
    
    private func getSharedData() -> [String: Any]? {
        guard let userDefaults = UserDefaults(suiteName: groupIdentifier) else {
            return nil
        }
        
        guard let sharedData = userDefaults.dictionary(forKey: sharedKey) else {
            return nil
        }
        
        // Clear after reading
        userDefaults.removeObject(forKey: sharedKey)
        userDefaults.synchronize()
        
        return sharedData
    }
}
