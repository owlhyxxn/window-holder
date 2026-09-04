import AppKit
import os.log

private let logger = Logger(subsystem: "com.local.windowholder", category: "app")

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController!
    private var sleepWakeMonitor: SleepWakeMonitor!
    private var periodicTimer: Timer?
    private var updateCheckTimer: Timer?
    private var lastWakeSettledAt: Date?

    private(set) var updateAvailable = false

    private let postWakeSaveCooldown: TimeInterval = 15

    var autoSaveEnabled = true

    func applicationDidFinishLaunching(_ notification: Notification) {
        _ = WindowManager.shared.isAccessibilityTrusted(prompt: true)

        statusBarController = StatusBarController(appDelegate: self)

        sleepWakeMonitor = SleepWakeMonitor(
            onSleep: { [weak self] in
                logger.log("willSleep — saving current layout")
                self?.saveCurrentLayout(reason: "willSleep")
            },
            onWake: { [weak self] in
                self?.lastWakeSettledAt = Date()
                self?.restoreCurrentLayout()
            }
        )

        periodicTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            guard let self, self.autoSaveEnabled else { return }
            if let lastWake = self.lastWakeSettledAt, Date().timeIntervalSince(lastWake) < self.postWakeSaveCooldown {
                logger.log("periodic save skipped: within post-wake cooldown")
                return
            }
            self.saveCurrentLayout(reason: "periodic")
        }

        saveCurrentLayout(reason: "launch")

        checkForUpdate()
        updateCheckTimer = Timer.scheduledTimer(withTimeInterval: 24 * 60 * 60, repeats: true) { [weak self] _ in
            self?.checkForUpdate()
        }
    }

    private func checkForUpdate() {
        VersionChecker.shared.checkForUpdate { [weak self] isNewer in
            guard let self else { return }
            if isNewer != self.updateAvailable {
                self.updateAvailable = isNewer
                if isNewer, let latest = VersionChecker.shared.latestVersion {
                    logger.log("update available: v\(latest, privacy: .public) (current v\(VersionChecker.shared.currentVersion, privacy: .public))")
                }
            }
        }
    }

    func saveCurrentLayout(reason: String = "manual") {
        guard WindowManager.shared.isAccessibilityTrusted(prompt: false) else { return }
        let fingerprint = DisplayFingerprint.current()
        let identityKey = DisplayFingerprint.currentIdentity()
        let windows = WindowManager.shared.captureCurrentLayout()
        let regularAppCount = WindowManager.shared.regularRunningAppCount()

        if regularAppCount >= 3 && windows.count < regularAppCount {
            logger.log("save[\(reason, privacy: .public)] SKIPPED (degenerate): regularApps=\(regularAppCount) windows=\(windows.count) fingerprint=\(fingerprint, privacy: .public)")
            return
        }

        logger.log("save[\(reason, privacy: .public)]: fingerprint=\(fingerprint, privacy: .public) identity=\(identityKey, privacy: .public) windows=\(windows.count) regularApps=\(regularAppCount)")
        SnapshotStore.shared.store(fingerprint: fingerprint, identityKey: identityKey, windows: windows)
    }

    func restoreCurrentLayout() {
        guard WindowManager.shared.isAccessibilityTrusted(prompt: false) else { return }
        let fingerprint = DisplayFingerprint.current()
        let identityKey = DisplayFingerprint.currentIdentity()
        guard let (layout, exact) = SnapshotStore.shared.bestLayout(fingerprint: fingerprint, identityKey: identityKey) else {
            logger.log("restore: no saved layout for fingerprint=\(fingerprint, privacy: .public) identity=\(identityKey, privacy: .public)")
            return
        }
        logger.log("restore: applying \(layout.windows.count) windows (exactMatch=\(exact)) fingerprint=\(fingerprint, privacy: .public)")
        WindowManager.shared.apply(layout.windows)
    }
}
