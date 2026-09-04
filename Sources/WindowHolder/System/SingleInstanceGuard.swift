import AppKit
import os.log

private let logger = Logger(subsystem: "com.local.windowholder", category: "instance")

enum SingleInstanceGuard {
    static func terminateIfAlreadyRunning() {
        let myPID = ProcessInfo.processInfo.processIdentifier
        let bundleID = Bundle.main.bundleIdentifier
        let alreadyRunning = NSWorkspace.shared.runningApplications.contains {
            $0.bundleIdentifier == bundleID && $0.processIdentifier != myPID
        }
        guard alreadyRunning else { return }
        logger.log("another instance is already running, quitting")
        exit(0)
    }
}
