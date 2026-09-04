import Foundation

enum LanguagePreference: String {
    case system
    case korean
    case english

    private static let defaultsKey = "com.local.windowholder.languagePreference"

    static var current: LanguagePreference {
        get {
            let raw = UserDefaults.standard.string(forKey: defaultsKey) ?? LanguagePreference.system.rawValue
            return LanguagePreference(rawValue: raw) ?? .system
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: defaultsKey)
        }
    }
}

enum Localization {
    static var isKorean: Bool {
        switch LanguagePreference.current {
        case .korean: return true
        case .english: return false
        case .system: return Locale.preferredLanguages.first?.hasPrefix("ko") ?? false
        }
    }

    static var accessibilityPermissionRequired: String {
        isKorean ? "⚠️ 손쉬운 사용 권한이 필요합니다…" : "⚠️ Accessibility permission required…"
    }

    static func updateAvailable(version: String) -> String {
        isKorean
            ? "🆕 새 버전 있음 (v\(version)) — 릴리즈 페이지 열기"
            : "🆕 Update available (v\(version)) — Open release page"
    }

    static var saveNow: String { isKorean ? "지금 배치 저장" : "Save Layout Now" }
    static var restoreNow: String { isKorean ? "지금 배치 복원" : "Restore Layout Now" }
    static var autoSave: String { isKorean ? "자동 저장 (1분 간격)" : "Auto-save (every minute)" }
    static var launchAtLogin: String { isKorean ? "로그인 시 자동 실행" : "Launch at Login" }
    static var quit: String { isKorean ? "종료" : "Quit" }

    static var savedStatus: String { isKorean ? "저장됨" : "saved" }
    static var noSavedStatus: String { isKorean ? "저장된 배치 없음" : "no saved layout" }

    static func infoLine(summary: String, status: String, total: Int) -> String {
        isKorean
            ? "현재: \(summary) — \(status)  (전체 \(total)개)"
            : "Current: \(summary) — \(status)  (\(total) total)"
    }

    static func displaySummary(count: Int) -> String {
        isKorean ? "\(count)개 디스플레이" : "\(count) display(s)"
    }

    static var languageMenuTitle: String { isKorean ? "언어" : "Language" }
    static var languageSystemOption: String { isKorean ? "시스템 언어 따르기" : "Use System Language" }
    static let languageKoreanOption = "한국어"
    static let languageEnglishOption = "English"
}
