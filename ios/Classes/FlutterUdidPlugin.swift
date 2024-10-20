import Flutter
import UIKit
import SAMKeychain

public class FlutterUdidPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_udid", binaryMessenger: registrar.messenger())
    let instance = FlutterUdidPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getUDID":
      self.getUniqueDeviceIdentifierAsString(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func getUniqueDeviceIdentifierAsString(result: FlutterResult) {
    let bundleName = Bundle.main.infoDictionary!["CFBundleName"] as! String
    let accountName = Bundle.main.bundleIdentifier!

    var applicationUUID: String?

    do {
      applicationUUID = try SAMKeychain.password(forService: bundleName, account: accountName)
    } catch let error as NSError {
      print("SAMKeychain.password Exception: \(error)")
      applicationUUID = nil
    }

    if applicationUUID == nil {
      if let uuid = UIDevice.current.identifierForVendor?.uuidString {
        applicationUUID = uuid
        let query = SAMKeychainQuery()
        query.service = bundleName
        query.account = accountName
        query.password = applicationUUID
        query.synchronizationMode = SAMKeychainQuerySynchronizationMode.no

        do {
          try query.save()
        } catch let error as NSError {
          print("SAMKeychainQuery save Exception: \(error)")
        }
      }
    }

    if applicationUUID == nil || applicationUUID == "" {
      result(FlutterError.init(code: "UNAVAILABLE",
                               message: "UDID not available",
                               details: nil))
    } else {
      result(applicationUUID)
    }
  }
}
