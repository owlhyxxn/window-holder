import Foundation

struct WindowRecord: Codable {
    var appBundleID: String
    var appName: String
    var title: String
    var index: Int
    var x: Double
    var y: Double
    var width: Double
    var height: Double
    var isMinimized: Bool
}

struct LayoutSnapshot: Codable {
    var fingerprint: String
    var identityKey: String?
    var displaySummary: String
    var savedAt: Date
    var windows: [WindowRecord]
}
