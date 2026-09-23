import Flutter
import GoogleMaps
import UIKit
import flutter_local_notifications
import AVFoundation
import app_links

@main
@objc class AppDelegate: FlutterAppDelegate {
    private var secureTextField: UITextField?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // This is required to make any communication available in the action isolate.
        FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
            GeneratedPluginRegistrant.register(with: registry)
        }

        UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
        GMSServices.provideAPIKey("____ GOOGLE API ______")
        GeneratedPluginRegistrant.register(with: self)
        if let url = AppLinks.shared.getLink(launchOptions: launchOptions) {
                  // We have a link, propagate it to your Flutter app or not
                  AppLinks.shared.handleLink(url: url)
                }

        let controller = window?.rootViewController as! FlutterViewController
        let channel = FlutterMethodChannel(name: "com.geoedu.app/screenshot", binaryMessenger: controller.binaryMessenger)
        channel.setMethodCallHandler { [weak self] (call, result) in
            switch call.method {
            case "enableSecure":
                self?.enableScreenshotPrevention()
                result(true)
            case "disableSecure":
                self?.disableScreenshotPrevention()
                result(true)
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    private func enableScreenshotPrevention() {
        guard secureTextField == nil else { return }
        let field = UITextField()
        field.isSecureTextEntry = true
        field.isUserInteractionEnabled = false
        if let window = self.window {
            window.addSubview(field)
            field.centerYAnchor.constraint(equalTo: window.centerYAnchor).isActive = true
            field.centerXAnchor.constraint(equalTo: window.centerXAnchor).isActive = true
            window.layer.superlayer?.addSublayer(field.layer)
            field.layer.sublayers?.first?.addSublayer(window.layer)
        }
        secureTextField = field
    }

    private func disableScreenshotPrevention() {
        secureTextField?.removeFromSuperview()
        secureTextField = nil
    }
}
