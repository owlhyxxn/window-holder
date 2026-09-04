import Foundation
import os.log

private let logger = Logger(subsystem: "com.local.windowholder", category: "install")

enum ApplicationsInstaller {
    private static let homebrewOptPaths = [
        "/opt/homebrew/opt/window-holder/WindowHolder.app",
        "/usr/local/opt/window-holder/WindowHolder.app",
    ]

    static func syncIfNeeded() {
        let runningBundlePath = Bundle.main.bundlePath
        let fm = FileManager.default

        let sourcePath: String
        if runningBundlePath.contains("Cellar/window-holder/") || runningBundlePath.contains("/opt/window-holder/") {
            sourcePath = runningBundlePath
        } else if let found = homebrewOptPaths.first(where: { fm.fileExists(atPath: $0) }) {
            sourcePath = found
        } else {
            return
        }

        let targetURL = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Applications/WindowHolder.app")
        let sourceVersion = Bundle(path: sourcePath)?.infoDictionary?["CFBundleShortVersionString"] as? String
        let targetVersion = Bundle(url: targetURL)?.infoDictionary?["CFBundleShortVersionString"] as? String
        guard sourceVersion != targetVersion else { return }

        do {
            try fm.createDirectory(at: targetURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            if fm.fileExists(atPath: targetURL.path) {
                try fm.removeItem(at: targetURL)
            }
            try fm.copyItem(atPath: sourcePath, toPath: targetURL.path)
            logger.log("synced \(sourcePath, privacy: .public) -> \(targetURL.path, privacy: .public) (v\(sourceVersion ?? "?", privacy: .public))")
        } catch {
            logger.log("sync to ~/Applications failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
