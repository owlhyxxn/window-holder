import AppKit

final class StatusBarController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private let menu = NSMenu()
    private weak var appDelegate: AppDelegate?

    init(appDelegate: AppDelegate) {
        self.appDelegate = appDelegate
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "rectangle.on.rectangle", accessibilityDescription: "Window Holder")
        }
        menu.delegate = self
        statusItem.menu = menu
        rebuildMenu()
    }

    func menuWillOpen(_ menu: NSMenu) {
        rebuildMenu()
    }

    private func rebuildMenu() {
        menu.removeAllItems()

        let versionItem = NSMenuItem(title: "Window Holder v\(VersionChecker.shared.currentVersion)", action: nil, keyEquivalent: "")
        versionItem.isEnabled = false
        menu.addItem(versionItem)
        menu.addItem(.separator())

        if appDelegate?.updateAvailable == true, let latest = VersionChecker.shared.latestVersion {
            let item = NSMenuItem(title: Localization.updateAvailable(version: latest),
                                   action: #selector(openReleasePage), keyEquivalent: "")
            item.target = self
            menu.addItem(item)
            menu.addItem(.separator())
        }

        let accessibilityGranted = WindowManager.shared.isAccessibilityTrusted(prompt: false)
        if !accessibilityGranted {
            let item = NSMenuItem(title: Localization.accessibilityPermissionRequired,
                                   action: #selector(openAccessibilitySettings), keyEquivalent: "")
            item.target = self
            menu.addItem(item)
            menu.addItem(.separator())
        }

        let saveItem = NSMenuItem(title: Localization.saveNow, action: #selector(saveNow), keyEquivalent: "s")
        saveItem.target = self
        menu.addItem(saveItem)

        let restoreItem = NSMenuItem(title: Localization.restoreNow, action: #selector(restoreNow), keyEquivalent: "r")
        restoreItem.target = self
        menu.addItem(restoreItem)

        menu.addItem(.separator())

        let autoSaveItem = NSMenuItem(title: Localization.autoSave, action: #selector(toggleAutoSave), keyEquivalent: "")
        autoSaveItem.target = self
        autoSaveItem.state = (appDelegate?.autoSaveEnabled ?? true) ? .on : .off
        menu.addItem(autoSaveItem)

        let loginItem = NSMenuItem(title: Localization.launchAtLogin, action: #selector(toggleLoginItem), keyEquivalent: "")
        loginItem.target = self
        loginItem.state = LoginItemManager.isEnabled ? .on : .off
        menu.addItem(loginItem)

        let languageParent = NSMenuItem(title: Localization.languageMenuTitle, action: nil, keyEquivalent: "")
        languageParent.submenu = buildLanguageSubmenu()
        menu.addItem(languageParent)

        menu.addItem(.separator())

        let currentFingerprint = DisplayFingerprint.current()
        let hasSavedForCurrent = SnapshotStore.shared.layout(for: currentFingerprint) != nil
        let statusText = hasSavedForCurrent ? Localization.savedStatus : Localization.noSavedStatus
        let infoItem = NSMenuItem(
            title: Localization.infoLine(summary: DisplayFingerprint.summary(), status: statusText, total: SnapshotStore.shared.layouts.count),
            action: nil, keyEquivalent: ""
        )
        infoItem.isEnabled = false
        menu.addItem(infoItem)

        menu.addItem(.separator())
        let quitItem = NSMenuItem(title: Localization.quit, action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }

    private func buildLanguageSubmenu() -> NSMenu {
        let submenu = NSMenu()
        let options: [(LanguagePreference, String)] = [
            (.system, Localization.languageSystemOption),
            (.korean, Localization.languageKoreanOption),
            (.english, Localization.languageEnglishOption),
        ]
        for (preference, title) in options {
            let item = NSMenuItem(title: title, action: #selector(selectLanguage(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = preference.rawValue
            item.state = LanguagePreference.current == preference ? .on : .off
            submenu.addItem(item)
        }
        return submenu
    }

    @objc private func selectLanguage(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String, let preference = LanguagePreference(rawValue: raw) else { return }
        LanguagePreference.current = preference
    }

    @objc private func saveNow() { appDelegate?.saveCurrentLayout() }
    @objc private func restoreNow() { appDelegate?.restoreCurrentLayout() }
    @objc private func toggleAutoSave() { appDelegate?.autoSaveEnabled.toggle() }
    @objc private func toggleLoginItem() { LoginItemManager.toggle() }

    @objc private func openReleasePage() {
        let url = VersionChecker.shared.latestReleaseURL
            ?? URL(string: "https://github.com/owlhyxxn/window-holder/releases")!
        NSWorkspace.shared.open(url)
    }

    @objc private func openAccessibilitySettings() {
        _ = WindowManager.shared.isAccessibilityTrusted(prompt: true)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func quit() { NSApp.terminate(nil) }
}
