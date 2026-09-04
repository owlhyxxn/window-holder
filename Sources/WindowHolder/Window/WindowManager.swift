import AppKit
import ApplicationServices

final class WindowManager {
    static let shared = WindowManager()

    func isAccessibilityTrusted(prompt: Bool = false) -> Bool {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let opts = [key: prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(opts)
    }

    func regularRunningAppCount() -> Int {
        let myPID = ProcessInfo.processInfo.processIdentifier
        return NSWorkspace.shared.runningApplications.filter {
            $0.activationPolicy == .regular && $0.processIdentifier != myPID
        }.count
    }

    func captureCurrentLayout() -> [WindowRecord] {
        var records: [WindowRecord] = []
        let myPID = ProcessInfo.processInfo.processIdentifier
        let apps = NSWorkspace.shared.runningApplications.filter {
            $0.activationPolicy == .regular && $0.processIdentifier != myPID
        }

        for app in apps {
            let axApp = AXUIElementCreateApplication(app.processIdentifier)
            guard let windows = copyWindows(of: axApp) else { continue }

            for (idx, win) in windows.enumerated() {
                guard let pos = getPoint(win, kAXPositionAttribute), let size = getSize(win, kAXSizeAttribute) else { continue }
                guard size.width > 1, size.height > 1 else { continue }
                let title = getString(win, kAXTitleAttribute) ?? ""
                let minimized = getBool(win, kAXMinimizedAttribute) ?? false
                records.append(WindowRecord(
                    appBundleID: app.bundleIdentifier ?? app.localizedName ?? "unknown",
                    appName: app.localizedName ?? "unknown",
                    title: title,
                    index: idx,
                    x: pos.x, y: pos.y, width: size.width, height: size.height,
                    isMinimized: minimized
                ))
            }
        }
        return records
    }

    func apply(_ records: [WindowRecord]) {
        let myPID = ProcessInfo.processInfo.processIdentifier
        let apps = NSWorkspace.shared.runningApplications.filter {
            $0.activationPolicy == .regular && $0.processIdentifier != myPID
        }
        let byBundle = Dictionary(grouping: records, by: { $0.appBundleID })

        for app in apps {
            let bundleID = app.bundleIdentifier ?? app.localizedName ?? "unknown"
            guard let wanted = byBundle[bundleID] else { continue }
            let axApp = AXUIElementCreateApplication(app.processIdentifier)
            guard let windows = copyWindows(of: axApp) else { continue }

            var remaining = wanted
            var usedWindowIdx = Set<Int>()

            for (i, win) in windows.enumerated() {
                let title = getString(win, kAXTitleAttribute) ?? ""
                guard !title.isEmpty else { continue }
                if let matchIdx = remaining.firstIndex(where: { $0.title == title }) {
                    applyFrame(remaining[matchIdx], to: win)
                    remaining.remove(at: matchIdx)
                    usedWindowIdx.insert(i)
                }
            }
            for (i, win) in windows.enumerated() where !usedWindowIdx.contains(i) {
                if let matchIdx = remaining.firstIndex(where: { $0.index == i }) {
                    applyFrame(remaining[matchIdx], to: win)
                    remaining.remove(at: matchIdx)
                    usedWindowIdx.insert(i)
                }
            }
        }
    }

    private func applyFrame(_ record: WindowRecord, to win: AXUIElement) {
        if record.isMinimized {
            setBool(win, kAXMinimizedAttribute, false)
        }
        var pos = CGPoint(x: record.x, y: record.y)
        var size = CGSize(width: record.width, height: record.height)
        if let posValue = AXValueCreate(.cgPoint, &pos) {
            AXUIElementSetAttributeValue(win, kAXPositionAttribute as CFString, posValue)
        }
        if let sizeValue = AXValueCreate(.cgSize, &size) {
            AXUIElementSetAttributeValue(win, kAXSizeAttribute as CFString, sizeValue)
        }
        if record.isMinimized {
            setBool(win, kAXMinimizedAttribute, true)
        }
    }

    private func copyWindows(of axApp: AXUIElement) -> [AXUIElement]? {
        var windowsRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &windowsRef)
        guard result == .success, let windows = windowsRef as? [AXUIElement] else { return nil }
        return windows
    }

    private func getPoint(_ element: AXUIElement, _ attr: String) -> CGPoint? {
        var ref: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attr as CFString, &ref) == .success, let value = ref else { return nil }
        guard CFGetTypeID(value) == AXValueGetTypeID() else { return nil }
        var point = CGPoint.zero
        guard AXValueGetValue(value as! AXValue, .cgPoint, &point) else { return nil }
        return point
    }

    private func getSize(_ element: AXUIElement, _ attr: String) -> CGSize? {
        var ref: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attr as CFString, &ref) == .success, let value = ref else { return nil }
        guard CFGetTypeID(value) == AXValueGetTypeID() else { return nil }
        var size = CGSize.zero
        guard AXValueGetValue(value as! AXValue, .cgSize, &size) else { return nil }
        return size
    }

    private func getString(_ element: AXUIElement, _ attr: String) -> String? {
        var ref: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attr as CFString, &ref) == .success else { return nil }
        return ref as? String
    }

    private func getBool(_ element: AXUIElement, _ attr: String) -> Bool? {
        var ref: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attr as CFString, &ref) == .success else { return nil }
        return (ref as? NSNumber)?.boolValue
    }

    private func setBool(_ element: AXUIElement, _ attr: String, _ value: Bool) {
        AXUIElementSetAttributeValue(element, attr as CFString, value ? kCFBooleanTrue : kCFBooleanFalse)
    }
}
