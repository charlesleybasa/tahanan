import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    replaceStaleSceneSessions(application)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // The native SwiftUI app shipped under the same bundle ID. After an update iOS restores its saved scene
  // session (delegate SwiftUI.AppSceneDelegate), which leaves Flutter with no view and a black screen.
  // Close any such session once launch finishes and open a fresh one with the Flutter configuration.
  private func replaceStaleSceneSessions(_ application: UIApplication) {
    let stale = application.openSessions.filter { $0.configuration.delegateClass != SceneDelegate.self }
    guard !stale.isEmpty else { return }
    DispatchQueue.main.async {
      application.activateSceneSession(for: UISceneSessionActivationRequest(role: .windowApplication)) { _ in }
      for session in stale {
        application.requestSceneSessionDestruction(session, options: nil)
      }
    }
  }

  // New sessions always get the Flutter configuration.
  override func application(
    _ application: UIApplication,
    configurationForConnecting connectingSceneSession: UISceneSession,
    options: UIScene.ConnectionOptions
  ) -> UISceneConfiguration {
    let config = UISceneConfiguration(name: "flutter", sessionRole: connectingSceneSession.role)
    config.delegateClass = SceneDelegate.self
    config.storyboard = UIStoryboard(name: "Main", bundle: nil)
    return config
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
