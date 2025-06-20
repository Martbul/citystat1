import UIKit
import Flutter
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let BADGE_CHANNEL = FlutterMethodChannel(name: "mobile.Lichess.org/badge",
                                                    binaryMessenger: controller.binaryMessenger)

    let SYSTEM_CHANNEL = FlutterMethodChannel(name: "mobile.Lichess.org/system",
                                                    binaryMessenger: controller.binaryMessenger)

    BADGE_CHANNEL.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      guard call.method == "setBadge" else {
        result(FlutterMethodNotImplemented)
        return
      }

        if let args = call.arguments as? Dictionary<String, Any>,
            let badge = args["badge"] as? Int {
            UIApplication.shared.applicationIconBadgeNumber = badge
            result(nil)
        } else {
            result(FlutterError(code: "bad_args", message: "bad arguments", details: nil))
        }
    })

    SYSTEM_CHANNEL.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      guard call.method == "getTotalRam" else {
        result(FlutterMethodNotImplemented)
        return
      }

      result(self.getPhysicalMemory())
    })

    // Cf: https://github.com/MaikuB/flutter_local_notifications/tree/master/flutter_local_notifications#notification-actions
    // This is required to make any communication available in the action isolate.
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
        GeneratedPluginRegistrant.register(with: registry)
    }

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func getPhysicalMemory() -> Int {
    let memory : Int = Int(ProcessInfo.processInfo.physicalMemory)
    let constant : Int = 1_048_576
    let res = memory / constant
    return Int(res)
  }
}
