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
      self.getUniqueDeviceIdentifierAsString(result: result);
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
          print("SAMKeychain.password 예외 발생: \(error)")
          applicationUUID = nil
      }

      if applicationUUID == nil {
          if let newUUID = self.hardwareUUID() {
              applicationUUID = newUUID

              let query = SAMKeychainQuery()
              query.service = bundleName
              query.account = accountName
              query.password = applicationUUID
              query.synchronizationMode = SAMKeychainQuerySynchronizationMode.no

              do {
                  try query.save()
              } catch let error as NSError {
                  print("SAMKeychainQuery 저장 예외 발생: \(error)")
              }
          } else {
              result(FlutterError.init(code: "UNAVAILABLE",
                                       message: "UDID not available",
                                       details: nil))
              return
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

  private func hardwareUUID() -> String?
  {
      let matchingDict = IOServiceMatching("IOPlatformExpertDevice")
      let platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault, matchingDict)
      defer{ IOObjectRelease(platformExpert) }

      guard platformExpert != 0 else { return nil }
      return IORegistryEntryCreateCFProperty(platformExpert, kIOPlatformUUIDKey as CFString, kCFAllocatorDefault, 0).takeRetainedValue() as? String
  }
}
