import AlarmKit
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController

    let alarmKitChannel = FlutterMethodChannel(
      name: "alarme_feriados/alarm_kit",
      binaryMessenger: controller.binaryMessenger
    )
    alarmKitChannel.setMethodCallHandler { (call, result) in
      guard call.method == "requestAlarmKitAuthorization" else {
        result(FlutterMethodNotImplemented)
        return
      }
      Task {
        let granted = await self.requestAlarmKitAuthorization()
        result(granted)
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // AKAlarmManager só existe no iOS 26+; o Podfile garante o mínimo, mas
  // o guard mantém segurança em tempo de compilação para SDKs futuros.
  @available(iOS 26.0, *)
  private func requestAlarmKitAuthorization() async -> Bool {
    do {
      let status = try await AKAlarmManager.shared.requestAuthorization()
      return status == .authorized
    } catch {
      return false
    }
  }
}
