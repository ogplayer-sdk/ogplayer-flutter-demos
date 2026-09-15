import Flutter
import UIKit
import ogplayer_flutter

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // OGPlayer fullscreen/rotate: portrait unless the player presents
  // fullscreen (see the plugin README's iOS requirements).
  override func application(
    _ application: UIApplication,
    supportedInterfaceOrientationsFor window: UIWindow?
  ) -> UIInterfaceOrientationMask {
    OgplayerFlutterPlugin.interfaceOrientationMask
  }

  // Downloads finished while the app wasn't running — hand the system's
  // completion handler to the SDK's background download session (see the
  // plugin README's iOS requirements).
  override func application(
    _ application: UIApplication,
    handleEventsForBackgroundURLSession identifier: String,
    completionHandler: @escaping () -> Void
  ) {
    if OgplayerFlutterPlugin.handleDownloadBackgroundEvents(
      identifier: identifier,
      completionHandler: completionHandler
    ) { return }
    super.application(
      application,
      handleEventsForBackgroundURLSession: identifier,
      completionHandler: completionHandler
    )
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
