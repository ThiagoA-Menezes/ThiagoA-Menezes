import AlarmKit
import AVFoundation
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  // Maps Flutter alarm id → AKAlarm identifier; persisted in UserDefaults so
  // alarmDidStart can resolve the id after an app kill/reboot.
  private var savedIds: [String: String] {
    get { UserDefaults.standard.dictionary(forKey: "_akIds") as? [String: String] ?? [:] }
    set { UserDefaults.standard.set(newValue, forKey: "_akIds") }
  }

  private var eventSink: FlutterEventSink?
  private var audioPlayer: AVAudioPlayer?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController

    let methodChannel = FlutterMethodChannel(
      name: "alarme_feriados/alarm_kit",
      binaryMessenger: controller.binaryMessenger
    )
    methodChannel.setMethodCallHandler { [weak self] call, result in
      guard #available(iOS 26.0, *) else {
        result(FlutterMethodNotImplemented)
        return
      }
      switch call.method {
      case "requestAlarmKitAuthorization":
        Task { result(await self?.requestAuthorization() ?? false) }
      case "scheduleAlarm":
        guard let args = call.arguments as? [String: Any],
              let id = args["id"] as? Int,
              let epochMs = args["epochMs"] as? Int64,
              let titulo = args["titulo"] as? String else {
          result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
          return
        }
        Task { await self?.scheduleAlarm(id: id, epochMs: epochMs, titulo: titulo, result: result) }
      case "cancelAlarm":
        guard let id = call.arguments as? Int else {
          result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
          return
        }
        Task { await self?.cancelAlarm(id: id, result: result) }
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let eventChannel = FlutterEventChannel(
      name: "alarme_feriados/alarm_kit_events",
      binaryMessenger: controller.binaryMessenger
    )
    eventChannel.setStreamHandler(self)

    if #available(iOS 26.0, *) {
      AKAlarmManager.shared.delegate = self
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // MARK: – AlarmKit

  @available(iOS 26.0, *)
  private func requestAuthorization() async -> Bool {
    do {
      return try await AKAlarmManager.shared.requestAuthorization() == .authorized
    } catch {
      return false
    }
  }

  @available(iOS 26.0, *)
  private func scheduleAlarm(id: Int, epochMs: Int64, titulo: String, result: @escaping FlutterResult) async {
    let date = Date(timeIntervalSince1970: Double(epochMs) / 1000.0)
    var components = Calendar.current.dateComponents(
      [.year, .month, .day, .hour, .minute], from: date
    )
    components.second = 0
    let alarm = AKAlarm(
      identifier: UUID().uuidString,
      trigger: .date(components),
      configuration: AKAlarmConfiguration(title: titulo)
    )
    do {
      try await AKAlarmManager.shared.add(alarm)
      var ids = savedIds
      ids["\(id)"] = alarm.identifier
      savedIds = ids
      result(nil)
    } catch {
      result(FlutterError(code: "SCHEDULE_ERROR", message: error.localizedDescription, details: nil))
    }
  }

  @available(iOS 26.0, *)
  private func cancelAlarm(id: Int, result: @escaping FlutterResult) async {
    guard let akId = savedIds["\(id)"] else { result(nil); return }
    do {
      try await AKAlarmManager.shared.remove(withIdentifiers: [akId])
      var ids = savedIds
      ids.removeValue(forKey: "\(id)")
      savedIds = ids
      result(nil)
    } catch {
      result(FlutterError(code: "CANCEL_ERROR", message: error.localizedDescription, details: nil))
    }
  }

  // MARK: – Audio

  private func playAudio() {
    guard audioPlayer == nil else { return }
    // Flutter asset bundled at flutter_assets/<assetAudioPath>
    guard let url = Bundle.main.url(
      forResource: "alarme", withExtension: "mp3",
      subdirectory: "flutter_assets/assets/audio"
    ) else { return }
    try? AVAudioSession.sharedInstance().setCategory(.playback, options: .duckOthers)
    try? AVAudioSession.sharedInstance().setActive(true)
    audioPlayer = try? AVAudioPlayer(contentsOf: url)
    audioPlayer?.numberOfLoops = -1
    audioPlayer?.play()
  }

  private func stopAudio() {
    audioPlayer?.stop()
    audioPlayer = nil
    try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
  }
}

// MARK: – AKAlarmDelegate

@available(iOS 26.0, *)
extension AppDelegate: AKAlarmDelegate {
  func alarmDidStart(_ alarm: AKAlarm) {
    let flutterIdStr = savedIds.first(where: { $0.value == alarm.identifier })?.key
    let flutterId = flutterIdStr.flatMap(Int.init) ?? -1
    playAudio()
    eventSink?(["id": flutterId, "titulo": alarm.configuration.title])
  }

  func alarmDidStop(_ alarm: AKAlarm) {
    stopAudio()
    var ids = savedIds
    ids = ids.filter { $0.value != alarm.identifier }
    savedIds = ids
  }
}

// MARK: – FlutterStreamHandler

extension AppDelegate: FlutterStreamHandler {
  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }
}
