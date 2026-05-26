import AppKit
import Carbon.HIToolbox

/// 글로벌 잠금 단축키 핸들러
/// Carbon RegisterEventHotKey API로 시스템 전역 단축키를 등록한다
@MainActor
final class LockHotkeyHandler {

    // MARK: - Properties

    /// 등록 중 여부
    private(set) var isMonitoring: Bool = false

    /// 단축키 트리거 시 호출되는 콜백
    var onTrigger: (() -> Void)?

    /// 등록된 핫키 ref
    private var hotKeyRef: EventHotKeyRef?

    /// 이벤트 핸들러 ref
    private var eventHandlerRef: EventHandlerRef?

    /// 단축키 관리자
    private let lockHotkeyManager: LockHotkeyManager

    /// 단축키 변경 알림 옵저버
    private var hotkeyChangeObserver: NSObjectProtocol?

    // MARK: - Lifecycle

    init(lockHotkeyManager: LockHotkeyManager = .shared) {
        self.lockHotkeyManager = lockHotkeyManager
    }

    deinit {
        if let observer = hotkeyChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
        }
    }

    // MARK: - Public Methods

    /// 글로벌 단축키 등록 시작
    @discardableResult
    func start() -> Bool {
        guard !isMonitoring else { return true }

        installEventHandlerIfNeeded()

        guard registerCurrentHotkey() else {
            return false
        }

        observeHotkeyChanges()
        isMonitoring = true
        return true
    }

    /// 글로벌 단축키 등록 해제
    func stop() {
        guard isMonitoring else { return }

        unregisterHotkey()

        if let observer = hotkeyChangeObserver {
            NotificationCenter.default.removeObserver(observer)
            hotkeyChangeObserver = nil
        }

        isMonitoring = false
    }

    /// 단축키 재등록 (사용자가 단축키를 변경했을 때)
    @discardableResult
    func reload() -> Bool {
        guard isMonitoring else { return false }
        unregisterHotkey()
        return registerCurrentHotkey()
    }

    // MARK: - Carbon Modifier Conversion

    /// NSEvent.ModifierFlags → Carbon modifier 변환
    static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var result: UInt32 = 0
        if flags.contains(.command) { result |= UInt32(cmdKey) }
        if flags.contains(.control) { result |= UInt32(controlKey) }
        if flags.contains(.option) { result |= UInt32(optionKey) }
        if flags.contains(.shift) { result |= UInt32(shiftKey) }
        return result
    }

    // MARK: - Private Methods

    private func registerCurrentHotkey() -> Bool {
        let combination = lockHotkeyManager.currentHotkey
        let modifiers = Self.carbonModifiers(from: combination.modifierFlags)

        var hotKeyID = EventHotKeyID(
            signature: OSType(0x434F4654), // "COFT"
            id: UInt32(1)
        )

        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(
            UInt32(combination.keyCode),
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &ref
        )

        guard status == noErr, let ref else {
            return false
        }

        hotKeyRef = ref
        return true
    }

    private func unregisterHotkey() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
    }

    private func installEventHandlerIfNeeded() {
        guard eventHandlerRef == nil else { return }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        var handlerRef: EventHandlerRef?
        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, _, userData) -> OSStatus in
                guard let userData else { return OSStatus(eventNotHandledErr) }
                let handler = Unmanaged<LockHotkeyHandler>.fromOpaque(userData).takeUnretainedValue()
                Task { @MainActor in
                    handler.onTrigger?()
                }
                return noErr
            },
            1,
            &eventType,
            selfPtr,
            &handlerRef
        )

        eventHandlerRef = handlerRef
    }

    private func observeHotkeyChanges() {
        guard hotkeyChangeObserver == nil else { return }

        hotkeyChangeObserver = NotificationCenter.default.addObserver(
            forName: LockHotkeyManager.hotkeyDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            MainActor.assumeIsolated {
                self.reload()
            }
        }
    }
}
