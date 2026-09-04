import AppKit

final class SleepWakeMonitor {
    private let onSleep: () -> Void
    private let onWake: () -> Void

    private var settleWorkItem: DispatchWorkItem?
    private var hardCutoffWorkItem: DispatchWorkItem?
    private var isWatchingForSettle = false

    private let settleDebounce: TimeInterval = 1.5
    private let hardCutoff: TimeInterval = 25.0
    private let safetyReapplyDelay: TimeInterval = 3.0

    init(onSleep: @escaping () -> Void, onWake: @escaping () -> Void) {
        self.onSleep = onSleep
        self.onWake = onWake

        let wsnc = NSWorkspace.shared.notificationCenter
        wsnc.addObserver(self, selector: #selector(handleWillSleep),
                          name: NSWorkspace.willSleepNotification, object: nil)
        wsnc.addObserver(self, selector: #selector(handleDidWake),
                          name: NSWorkspace.didWakeNotification, object: nil)
        wsnc.addObserver(self, selector: #selector(handleScreensDidWake),
                          name: NSWorkspace.screensDidWakeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleScreenParamsChanged),
                                                name: NSApplication.didChangeScreenParametersNotification, object: nil)
    }

    deinit {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func handleWillSleep() {
        onSleep()
    }

    @objc private func handleDidWake() {
        beginSettleWatch()
    }

    @objc private func handleScreensDidWake() {
        beginSettleWatch()
    }

    @objc private func handleScreenParamsChanged() {
        guard isWatchingForSettle else { return }
        scheduleSettleCheck()
    }

    private func beginSettleWatch() {
        guard !isWatchingForSettle else {
            scheduleSettleCheck()
            return
        }
        isWatchingForSettle = true
        hardCutoffWorkItem?.cancel()
        let cutoff = DispatchWorkItem { [weak self] in self?.finishSettleWatch() }
        hardCutoffWorkItem = cutoff
        DispatchQueue.main.asyncAfter(deadline: .now() + hardCutoff, execute: cutoff)
        scheduleSettleCheck()
    }

    private func scheduleSettleCheck() {
        settleWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in self?.finishSettleWatch() }
        settleWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + settleDebounce, execute: item)
    }

    private func finishSettleWatch() {
        guard isWatchingForSettle else { return }
        isWatchingForSettle = false
        settleWorkItem?.cancel()
        hardCutoffWorkItem?.cancel()
        onWake()
        DispatchQueue.main.asyncAfter(deadline: .now() + safetyReapplyDelay) { [weak self] in
            self?.onWake()
        }
    }
}
