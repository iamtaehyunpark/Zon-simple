import UIKit
import UniformTypeIdentifiers
import ImageIO
import AVFoundation

// App Group identifier — must match Runner.entitlements and ShareExtension.entitlements.
private let kAppGroup = "group.app.getzon.zon"
// URL scheme of the main app — used to bring it to the foreground after saving.
private let kAppScheme = "app.getzon"
// UserDefaults key under which pending photo metadata is stored.
private let kDefaultsKey = "sharedPhotosMetadata"
// UserDefaults key + URL host for shared voice memos.
private let kVoiceDefaultsKey = "sharedVoiceMemos"

class ShareViewController: UIViewController {

    private var pendingCount = 0
    private var savedItems: [[String: Any]] = []
    // Which kind of share we're handling — selects the UserDefaults key + URL host.
    private var isVoice = false

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemBackground

        let label = UILabel()
        label.text = "Sending to ZON…"
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        processItems()
    }

    // MARK: - Processing

    private func processItems() {
        guard let item = extensionContext?.inputItems.first as? NSExtensionItem,
              let attachments = item.attachments, !attachments.isEmpty else {
            complete(success: false)
            return
        }

        let imageType = UTType.image.identifier
        let audioType = UTType.audio.identifier
        let imageAttachments = attachments.filter { $0.hasItemConformingToTypeIdentifier(imageType) }
        let audioAttachments = attachments.filter { $0.hasItemConformingToTypeIdentifier(audioType) }

        // Photos take precedence; otherwise handle voice memos.
        if imageAttachments.isEmpty, !audioAttachments.isEmpty {
            isVoice = true
            processAudio(audioAttachments)
            return
        }
        guard !imageAttachments.isEmpty else {
            complete(success: false)
            return
        }

        pendingCount = imageAttachments.count

        for provider in imageAttachments {
            // loadFileRepresentation gives a temporary file URL with EXIF intact.
            provider.loadFileRepresentation(forTypeIdentifier: imageType) { [weak self] url, error in
                guard let self = self else { return }
                defer { self.checkDone() }

                guard let url = url, error == nil else { return }

                // Read EXIF to get GPS + timestamp before the temp URL is cleaned up.
                let (lat, lng, ts) = Self.exifFrom(url: url)

                // Copy to the shared App Group container so the main app can access it.
                guard let containerURL = FileManager.default
                        .containerURL(forSecurityApplicationGroupIdentifier: kAppGroup)?
                        .appendingPathComponent("shared_photos", isDirectory: true) else { return }

                try? FileManager.default.createDirectory(at: containerURL,
                                                         withIntermediateDirectories: true)

                let dest = containerURL.appendingPathComponent(
                    "\(UUID().uuidString).\(url.pathExtension)")
                try? FileManager.default.copyItem(at: url, to: dest)

                let entry: [String: Any] = [
                    "path": dest.path,
                    "lat": lat,
                    "lng": lng,
                    "timestamp": ts,
                ]
                DispatchQueue.main.async { self.savedItems.append(entry) }
            }
        }
    }

    // MARK: - Audio (voice memos)

    private func processAudio(_ providers: [NSItemProvider]) {
        pendingCount = providers.count
        let audioType = UTType.audio.identifier
        for provider in providers {
            provider.loadFileRepresentation(forTypeIdentifier: audioType) { [weak self] url, error in
                guard let self = self else { return }
                defer { self.checkDone() }
                guard let url = url, error == nil else { return }

                guard let containerURL = FileManager.default
                        .containerURL(forSecurityApplicationGroupIdentifier: kAppGroup)?
                        .appendingPathComponent("shared_voice", isDirectory: true) else { return }
                try? FileManager.default.createDirectory(at: containerURL,
                                                         withIntermediateDirectories: true)

                let ext = url.pathExtension.isEmpty ? "m4a" : url.pathExtension
                let dest = containerURL.appendingPathComponent("\(UUID().uuidString).\(ext)")
                try? FileManager.default.copyItem(at: url, to: dest)

                let entry: [String: Any] = [
                    "path": dest.path,
                    "recordedAt": Self.recordingDate(of: url),
                ]
                DispatchQueue.main.async { self.savedItems.append(entry) }
            }
        }
    }

    /// Best-effort original recording date as ISO-8601: audio metadata → file attrs → now.
    private static func recordingDate(of url: URL) -> String {
        let iso = ISO8601DateFormatter()
        if let created = AVURLAsset(url: url).creationDate?.dateValue {
            return iso.string(from: created)
        }
        if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
           let created = attrs[.creationDate] as? Date {
            return iso.string(from: created)
        }
        return iso.string(from: Date())
    }

    private func checkDone() {
        pendingCount -= 1
        guard pendingCount <= 0 else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            // Persist metadata to App Group UserDefaults so the main app can read it.
            let key = self.isVoice ? kVoiceDefaultsKey : kDefaultsKey
            if let defaults = UserDefaults(suiteName: kAppGroup) {
                var existing = defaults.array(forKey: key) as? [[String: Any]] ?? []
                existing.append(contentsOf: self.savedItems)
                defaults.set(existing, forKey: key)
            }
            self.openMainApp()
        }
    }

    private func openMainApp() {
        let host = isVoice ? "shared-voice" : "shared-photos"
        guard let url = URL(string: "\(kAppScheme)://\(host)") else {
            complete(success: true)
            return
        }
        // Responder-chain approach — works in iOS 15+ Share Extensions.
        var responder: UIResponder? = self
        while let r = responder {
            if let app = r as? UIApplication {
                app.open(url)
                break
            }
            responder = r.next
        }
        complete(success: true)
    }

    private func complete(success: Bool) {
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }

    // MARK: - EXIF parsing

    /// Returns (latitude, longitude, ISO-8601 timestamp) from EXIF embedded in the file.
    /// Falls back to (0.0, 0.0, epoch) when data is missing.
    private static func exifFrom(url: URL) -> (Double, Double, String) {
        guard let src = CGImageSourceCreateWithURL(url as CFURL, nil),
              let props = CGImageSourceCopyPropertiesAtIndex(src, 0, nil) as? [String: Any]
        else { return (0, 0, isoNow()) }

        // GPS
        var lat = 0.0, lng = 0.0
        if let gps = props[kCGImagePropertyGPSDictionary as String] as? [String: Any],
           let rawLat = gps[kCGImagePropertyGPSLatitude as String] as? Double,
           let rawLng = gps[kCGImagePropertyGPSLongitude as String] as? Double {
            let latRef = gps[kCGImagePropertyGPSLatitudeRef as String] as? String ?? "N"
            let lngRef = gps[kCGImagePropertyGPSLongitudeRef as String] as? String ?? "E"
            lat = latRef == "S" ? -rawLat : rawLat
            lng = lngRef == "W" ? -rawLng : rawLng
        }

        // Timestamp from EXIF DateTimeOriginal → fallback to GPS → fallback to now
        var timestamp = isoNow()
        if let exif = props[kCGImagePropertyExifDictionary as String] as? [String: Any],
           let dtStr = exif[kCGImagePropertyExifDateTimeOriginal as String] as? String {
            // EXIF format: "YYYY:MM:DD HH:MM:SS"
            let fmt = DateFormatter()
            fmt.dateFormat = "yyyy:MM:dd HH:mm:ss"
            fmt.locale = Locale(identifier: "en_US_POSIX")
            if let dt = fmt.date(from: dtStr) {
                let isoFmt = ISO8601DateFormatter()
                timestamp = isoFmt.string(from: dt)
            }
        }

        return (lat, lng, timestamp)
    }

    private static func isoNow() -> String {
        ISO8601DateFormatter().string(from: Date())
    }
}
