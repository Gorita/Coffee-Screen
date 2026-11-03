import AppKit
import Foundation
import IOKit

/// macOS 디스플레이 꺼짐 또는 화면 보호기 실행 직전에
/// 주기적인 무한 폴링(Polling) 없이 원샷(One-Shot) 타이머로 Coffee-Screen 잠금을 자동 트리거하는 컨트롤러
@MainActor
final class SleepAutoLockController {

    // MARK: - Notification / Key Constants

    static let autoLockSettingKey = "autoLockBeforeSleepEnabled"

    // MARK: - Properties

    /// 화면 잠금 트리거 콜백 (Main Thread 보장)
    var onTriggerLock: (() -> Void)?

    /// 기능 활성화 여부 (UserDefaults 저장, 기본값: true)
    var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: Self.autoLockSettingKey)
            if isEnabled {
                scheduleNextCheck()
            } else {
                cancelTimer()
            }
        }
    }

    /// 현재 잠금 상태 (잠금 중에는 감시 중단)
    var isLocked: Bool = false {
        didSet {
            if isLocked {
                cancelTimer()
            } else if isEnabled {
                scheduleNextCheck()
            }
        }
    }

    /// 원샷 타이머 (Zero-Polling)
    private var oneShotTimer: DispatchSourceTimer?

    /// 시스템 알림 옵저버 토큰
    private var notificationObservers: [NSObjectProtocol] = []

    // MARK: - Initialization

    init() {
        // UserDefaults에서 설정값 복원 (기본값 true)
        if UserDefaults.standard.object(forKey: Self.autoLockSettingKey) == nil {
            UserDefaults.standard.set(true, forKey: Self.autoLockSettingKey)
            self.isEnabled = true
        } else {
            self.isEnabled = UserDefaults.standard.bool(forKey: Self.autoLockSettingKey)
        }

        setupSystemNotificationObservers()

        if isEnabled {
            scheduleNextCheck()
        }
    }

    deinit {
        oneShotTimer?.cancel()
        notificationObservers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    // MARK: - Public Control Methods

    /// 외부 이벤트(예: 유저 활동, 잠금 해제)에 따른 스케줄러 갱신
    func scheduleNextCheck() {
        cancelTimer()

        guard isEnabled, !isLocked else { return }

        guard let effectiveTimeout = getEffectiveSleepTimeoutSeconds() else {
            // 시스템 잠자기가 '안 함(Never)'으로 설정된 경우
            return
        }

        // 잠들기 전 여유 버퍼 (기본 15초, 전체 시간이 매우 짧을 경우 비율 조정)
        let leadTime: Double
        if effectiveTimeout <= 30 {
            leadTime = max(3.0, effectiveTimeout * 0.2)
        } else if effectiveTimeout <= 60 {
            leadTime = 15.0
        } else {
            leadTime = 15.0
        }

        let targetIdleSeconds = max(5.0, effectiveTimeout - leadTime)
        let currentIdle = getSystemIdleSeconds()
        let remainingSeconds = targetIdleSeconds - currentIdle

        if remainingSeconds <= 0.8 {
            // 이미 유휴 시간이 임계치에 도달한 상태 -> 잠금 실행
            triggerAutoLock()
        } else {
            // 남은 시간만큼만 잠자는 단일 원샷 타이머 등록 (CPU 웨이크업 0%)
            scheduleOneShotTimer(after: remainingSeconds)
        }
    }

    // MARK: - Private Scheduling & Execution

    private func scheduleOneShotTimer(after seconds: Double) {
        cancelTimer()

        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + seconds, leeway: .milliseconds(300))
        timer.setEventHandler { [weak self] in
            guard let self = self else { return }
            self.handleTimerFired()
        }
        timer.resume()
        self.oneShotTimer = timer
    }

    private func handleTimerFired() {
        cancelTimer()

        guard isEnabled, !isLocked else { return }

        guard let effectiveTimeout = getEffectiveSleepTimeoutSeconds() else { return }

        let leadTime = effectiveTimeout <= 60 ? 15.0 : 15.0
        let targetIdleSeconds = max(5.0, effectiveTimeout - leadTime)
        let currentIdle = getSystemIdleSeconds()

        if currentIdle >= targetIdleSeconds {
            // 유저가 방해하지 않고 목표 시간에 정상 도달 -> 자동 잠금 실행!
            triggerAutoLock()
        } else {
            // 유저가 중간에 마우스/키보드를 조작했음 -> 다음 남은 시간 뒤로 원샷 타이머 1회 재예약
            scheduleNextCheck()
        }
    }

    private func triggerAutoLock() {
        cancelTimer()
        guard isEnabled, !isLocked else { return }
        onTriggerLock?()
    }

    private func cancelTimer() {
        oneShotTimer?.cancel()
        oneShotTimer = nil
    }

    // MARK: - System Query Helpers

    /// 시스템 IOKit 커널로부터 사용자 무입력 유휴 시간(초)을 나노초 단위 정밀도로 조회 (권한 불필요)
    func getSystemIdleSeconds() -> Double {
        var iterator: io_iterator_t = 0
        let result = IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IOHIDSystem"), &iterator)
        guard result == KERN_SUCCESS else { return 0 }
        defer { IOObjectRelease(iterator) }

        let entry = IOIteratorNext(iterator)
        guard entry != 0 else { return 0 }
        defer { IOObjectRelease(entry) }

        var unmanagedDict: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(entry, &unmanagedDict, kCFAllocatorDefault, 0) == KERN_SUCCESS,
              let dict = unmanagedDict?.takeRetainedValue() as? [String: Any],
              let nanoseconds = dict["HIDIdleTime"] as? Int64 else {
            return 0
        }
        return Double(nanoseconds) / 1_000_000_000.0
    }

    /// 디스플레이 꺼짐(displaysleep)과 화면 보호기(screensaver) 중 더 짧은 쪽의 유효 시간(초) 계산
    func getEffectiveSleepTimeoutSeconds() -> Double? {
        let displaysleepSec = getDisplaysleepSeconds()
        let screensaverSec = getScreensaverSeconds()

        var candidates: [Double] = []
        if let ds = displaysleepSec, ds > 0 {
            candidates.append(ds)
        }
        if let ss = screensaverSec, ss > 0 {
            candidates.append(ss)
        }

        return candidates.min()
    }

    /// pmset -g를 통해 현재 디스플레이 꺼짐 시간(초) 확인
    private func getDisplaysleepSeconds() -> Double? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        process.arguments = ["-g"]
        let pipe = Pipe()
        process.standardOutput = pipe

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let text = String(data: data, encoding: .utf8) {
                for line in text.split(separator: "\n") {
                    let trimmed = line.trimmingCharacters(in: .whitespaces)
                    if trimmed.hasPrefix("displaysleep") {
                        let parts = trimmed.split(separator: " ", omittingEmptySubsequences: true)
                        if parts.count >= 2, let mins = Double(parts[1]), mins > 0 {
                            return mins * 60.0
                        }
                    }
                }
            }
        } catch {}
        return nil
    }

    /// 화면 보호기 대기 시간(초) 확인
    private func getScreensaverSeconds() -> Double? {
        if let value = CFPreferencesCopyValue(
            "idleTime" as CFString,
            "com.apple.screensaver" as CFString,
            kCFPreferencesCurrentUser,
            kCFPreferencesCurrentHost
        ) as? Int, value > 0 {
            return Double(value)
        }
        return nil
    }

    // MARK: - System Notifications Observation

    private func setupSystemNotificationObservers() {
        let center = NSWorkspace.shared.notificationCenter

        // 시스템 깨어남 감지
        let wakeObserver = center.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.scheduleNextCheck()
        }
        notificationObservers.append(wakeObserver)

        // 화면 켜짐 감지
        let screenWakeObserver = center.addObserver(
            forName: NSWorkspace.screensDidWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.scheduleNextCheck()
        }
        notificationObservers.append(screenWakeObserver)

        // 화면 꺼짐 감지
        let screenSleepObserver = center.addObserver(
            forName: NSWorkspace.screensDidSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.cancelTimer()
        }
        notificationObservers.append(screenSleepObserver)
    }
}
