import Foundation
import os.log

private let logger = Logger(subsystem: "com.local.windowholder", category: "install")

enum ApplicationsInstaller {
    static func installIfNeeded() {
        let bundlePath = Bundle.main.bundlePath
        guard bundlePath.contains("Cellar/window-holder/") || bundlePath.contains("/opt/window-holder/") else { return }

        let targetURL = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Applications/WindowHolder.app")
        let fm = FileManager.default

        let sourceVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let targetVersion = Bundle(url: targetURL)?.infoDictionary?["CFBundleShortVersionString"] as? String
        guard sourceVersion != targetVersion else { return }

        do {
            try fm.createDirectory(at: targetURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            if fm.fileExists(atPath: targetURL.path) {
                try fm.removeItem(at: targetURL)
            }
            try fm.copyItem(at: URL(fileURLWithPath: bundlePath), to: targetURL)
            logger.log("copied to \(targetURL.path, privacy: .public) (v\(sourceVersion ?? "?", privacy: .public))")
        } catch {
            logger.log("copy to ~/Applications failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
