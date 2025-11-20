import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
    private var methodChannel: FlutterMethodChannel?
    private var shareHandler: ShareHandler?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        let controller = window?.rootViewController as! FlutterViewController
        
        // Setup MethodChannel
        methodChannel = FlutterMethodChannel(
            name: "id.bee.sharemanual/share",
            binaryMessenger: controller.binaryMessenger
        )
        
        // Initialize ShareHandler
        shareHandler = ShareHandler(methodChannel: methodChannel)
        
        // Setup method call handler
        methodChannel?.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else { return }
            
            switch call.method {
            case "getInitialShare":
                let data = self.shareHandler?.getInitialShareData() ?? [:]
                result(data)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // Handle URL dari Share Extension atau deep link
    override func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        // Handle shared content jika ada
        shareHandler?.handleSharedContent(url: url)
        return super.application(app, open: url, options: options)
    }
}
