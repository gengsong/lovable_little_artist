import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var storageChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "LittleArtistStorage")
    storageChannel = FlutterMethodChannel(name: "little_artist/storage", binaryMessenger: registrar.messenger())
    storageChannel?.setMethodCallHandler { call, result in
      switch call.method {
      case "readSavedArtworks":
        result(UserDefaults.standard.string(forKey: "saved_artworks_v1"))
      case "writeSavedArtworks":
        UserDefaults.standard.set(call.arguments as? String ?? "[]", forKey: "saved_artworks_v1")
        result(nil)
      case "clearSavedArtworks":
        UserDefaults.standard.removeObject(forKey: "saved_artworks_v1")
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
