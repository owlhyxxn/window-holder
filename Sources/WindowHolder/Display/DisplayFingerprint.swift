import AppKit
import CoreGraphics

enum DisplayFingerprint {
    static func current() -> String {
        let screens = NSScreen.screens
        let parts = screens.compactMap { screen -> String? in
            guard let num = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
                return nil
            }
            let displayID = CGDirectDisplayID(num.uint32Value)
            let serial = CGDisplaySerialNumber(displayID)
            let vendor = CGDisplayVendorNumber(displayID)
            let model = CGDisplayModelNumber(displayID)
            let frame = screen.frame
            return "\(vendor)_\(model)_\(serial)@\(Int(frame.origin.x)),\(Int(frame.origin.y)),\(Int(frame.width))x\(Int(frame.height))"
        }.sorted()
        return parts.joined(separator: "|")
    }

    static func currentIdentity() -> String {
        let screens = NSScreen.screens
        let parts = screens.compactMap { screen -> String? in
            guard let num = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
                return nil
            }
            let displayID = CGDirectDisplayID(num.uint32Value)
            let serial = CGDisplaySerialNumber(displayID)
            let vendor = CGDisplayVendorNumber(displayID)
            let model = CGDisplayModelNumber(displayID)
            return "\(vendor)_\(model)_\(serial)"
        }.sorted()
        return parts.joined(separator: "|")
    }

    static func summary() -> String {
        Localization.displaySummary(count: NSScreen.screens.count)
    }
}
