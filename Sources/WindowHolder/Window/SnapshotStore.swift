import Foundation

final class SnapshotStore {
    static let shared = SnapshotStore()

    private let fileURL: URL
    private(set) var layouts: [String: LayoutSnapshot] = [:]

    private init() {
        let supportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("WindowHolder", isDirectory: true)
        try? FileManager.default.createDirectory(at: supportDir, withIntermediateDirectories: true)
        fileURL = supportDir.appendingPathComponent("layouts.json")
        load()
    }

    func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let decoded = try? decoder.decode([String: LayoutSnapshot].self, from: data) {
            layouts = decoded
        }
    }

    func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(layouts) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    func store(fingerprint: String, identityKey: String, windows: [WindowRecord]) {
        guard !windows.isEmpty else { return }
        layouts[fingerprint] = LayoutSnapshot(
            fingerprint: fingerprint,
            identityKey: identityKey,
            displaySummary: DisplayFingerprint.summary(),
            savedAt: Date(),
            windows: windows
        )
        save()
    }

    func layout(for fingerprint: String) -> LayoutSnapshot? {
        layouts[fingerprint]
    }

    func bestLayout(fingerprint: String, identityKey: String) -> (LayoutSnapshot, exact: Bool)? {
        if let exact = layouts[fingerprint], exact.windows.count >= 3 {
            return (exact, true)
        }
        let candidates = layouts.values.filter { $0.identityKey == identityKey }
        guard let richest = candidates.max(by: {
            ($0.windows.count, $0.savedAt) < ($1.windows.count, $1.savedAt)
        }) else {
            return layouts[fingerprint].map { ($0, true) }
        }
        return (richest, richest.fingerprint == fingerprint)
    }

    func delete(fingerprint: String) {
        layouts.removeValue(forKey: fingerprint)
        save()
    }
}
