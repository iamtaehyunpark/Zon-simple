import Flutter
import UIKit
import Speech

private let kAppGroup         = "group.app.getzon.zon"
private let kDefaultsKey      = "sharedPhotosMetadata"
private let kVoiceDefaultsKey = "sharedVoiceMemos"
private let kChannelName      = "app.getzon.zon/sharing"

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var speechChannel: FlutterMethodChannel?
  private var sharingChannel: FlutterMethodChannel?
  // Shared items that arrived before the Flutter engine was ready.
  private var pendingSharedPhotos: [[String: Any]]?
  private var pendingSharedVoiceMemos: [[String: Any]]?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Called when the main app is opened via the app.getzon:// URL scheme
  // (triggered by the Share Extension after saving photos).
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    if url.scheme == "app.getzon" && url.host == "shared-photos" {
      readAndForwardSharedPhotos()
      return true
    }
    if url.scheme == "app.getzon" && url.host == "shared-voice" {
      readAndForwardSharedVoiceMemos()
      return true
    }
    return super.application(app, open: url, options: options)
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    // Also check on every foreground in case the URL open was missed.
    readAndForwardSharedPhotos()
    readAndForwardSharedVoiceMemos()
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // ── Speech channel ──────────────────────────────────────────────────────
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "VoiceTranscriber") {
      let channel = FlutterMethodChannel(
        name: "app.getzon.zon/speech", binaryMessenger: registrar.messenger())
      channel.setMethodCallHandler { [weak self] call, result in
        self?.handle(call, result: result)
      }
      speechChannel = channel
    }

    // ── Sharing channel ─────────────────────────────────────────────────────
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "SharedPhotos") {
      let channel = FlutterMethodChannel(
        name: kChannelName, binaryMessenger: registrar.messenger())
      channel.setMethodCallHandler { [weak self] call, result in
        guard let self = self else { return result(FlutterMethodNotImplemented) }
        switch call.method {
        case "getPending":
          // Flutter polls once on launch to pick up any photos from a cold start.
          if let photos = self.pendingSharedPhotos, !photos.isEmpty {
            result(photos)
            self.pendingSharedPhotos = nil
          } else {
            result(nil)
          }
        case "getPendingVoiceMemos":
          // Same, for voice memos shared while the app was closed.
          if let memos = self.pendingSharedVoiceMemos, !memos.isEmpty {
            result(memos)
            self.pendingSharedVoiceMemos = nil
          } else {
            result(nil)
          }
        default:
          result(FlutterMethodNotImplemented)
        }
      }
      sharingChannel = channel

      // Deliver any items that arrived before the engine was ready.
      if let photos = pendingSharedPhotos, !photos.isEmpty {
        channel.invokeMethod("sharedPhotos", arguments: photos)
        pendingSharedPhotos = nil
      }
      if let memos = pendingSharedVoiceMemos, !memos.isEmpty {
        channel.invokeMethod("sharedVoiceMemos", arguments: memos)
        pendingSharedVoiceMemos = nil
      }
    }
  }

  // MARK: - Shared photo reading

  private func readAndForwardSharedPhotos() {
    guard let defaults = UserDefaults(suiteName: kAppGroup) else { return }
    guard let items = defaults.array(forKey: kDefaultsKey) as? [[String: Any]],
          !items.isEmpty else { return }
    // Clear immediately so a second foreground doesn't re-deliver.
    defaults.removeObject(forKey: kDefaultsKey)

    if let channel = sharingChannel {
      channel.invokeMethod("sharedPhotos", arguments: items)
    } else {
      // Engine not ready yet — buffer until didInitializeImplicitFlutterEngine fires.
      pendingSharedPhotos = (pendingSharedPhotos ?? []) + items
    }
  }

  // MARK: - Shared voice-memo reading

  private func readAndForwardSharedVoiceMemos() {
    guard let defaults = UserDefaults(suiteName: kAppGroup) else { return }
    guard let items = defaults.array(forKey: kVoiceDefaultsKey) as? [[String: Any]],
          !items.isEmpty else { return }
    // Clear immediately so a second foreground doesn't re-deliver.
    defaults.removeObject(forKey: kVoiceDefaultsKey)

    if let channel = sharingChannel {
      channel.invokeMethod("sharedVoiceMemos", arguments: items)
    } else {
      pendingSharedVoiceMemos = (pendingSharedVoiceMemos ?? []) + items
    }
  }

  // MARK: - Speech

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "requestAuthorization":
      SFSpeechRecognizer.requestAuthorization { status in
        DispatchQueue.main.async { result(status == .authorized) }
      }
    case "transcribe":
      let args = call.arguments as? [String: Any]
      guard let path = args?["path"] as? String else {
        result(FlutterError(code: "bad_args", message: "path is required", details: nil))
        return
      }
      transcribe(path: path, localeId: args?["localeId"] as? String, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func transcribe(path: String, localeId: String?, result: @escaping FlutterResult) {
    let recognizer: SFSpeechRecognizer?
    if let id = localeId {
      recognizer = SFSpeechRecognizer(locale: Locale(identifier: id)) ?? SFSpeechRecognizer()
    } else {
      recognizer = SFSpeechRecognizer()
    }
    guard let recognizer = recognizer, recognizer.isAvailable else {
      result(FlutterError(code: "unavailable",
                          message: "Speech recognition unavailable for this locale", details: nil))
      return
    }

    let request = SFSpeechURLRecognitionRequest(url: URL(fileURLWithPath: path))
    request.shouldReportPartialResults = false
    if recognizer.supportsOnDeviceRecognition {
      request.requiresOnDeviceRecognition = true
    }

    recognizer.recognitionTask(with: request) { rec, error in
      if let error = error {
        result(FlutterError(code: "recognition_failed",
                            message: error.localizedDescription, details: nil))
        return
      }
      guard let rec = rec, rec.isFinal else { return }
      result(rec.bestTranscription.formattedString)
    }
  }
}
