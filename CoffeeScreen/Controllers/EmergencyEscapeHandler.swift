import AppKit
import Carbon.HIToolbox

/// 비상 탈출 키 조합 핸들러
/// 양쪽 Shift + Cmd + L 키 조합을 감지하여 긴급 잠금 해제
@MainActor
final class EmergencyEscapeHandler {

    // MARK: - Constants

    /// L 키 코드
    private static let lKeyCode: UInt16 = 0x25 // 37

    /// Left Shift 키 코드
    private static let leftShiftKeyCode: UInt16 = 56

    /// Right Shift 키 코드
    private static let rightShiftKeyCode: UInt16 = 60

    // MARK: - Properties

    /// 모니터링 중 여부
    private(set) var isMonitoring: Bool = false

    /// 비상 탈출 시 호출되는 콜백
    var onEscape: (() -> Void)?

    /// 로컬 키 이벤트 모니터
    private var localMonitor: Any?

    /// 양쪽 Shift 키 상태 추적
    private var leftShiftPressed: Bool = false
    private var rightShiftPressed: Bool = false

    // MARK: - Lifecycle

    deinit {
        // deinit에서는 MainActor가 아니므로 monitor 제거만 수행
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    // MARK: - Public Methods

    /// 비상 탈출 키 모니터링 시작
    func start() {
        guard !isMonitoring else { return }

        // Shift 키 상태 추적을 위한 flagsChanged 모니터
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
            guard let self else { return event }

            return MainActor.assumeIsolated {
                self.handleEvent(event)
            }
        }

        isMonitoring = true
    }

    /// 비상 탈출 키 모니터링 중지
    func stop() {
        guard isMonitoring else { return }

        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }

        leftShiftPressed = false
        rightShiftPressed = false
        isMonitoring = false
    }

    /// 비상 탈출 키 조합인지 확인 (테스트용)
    func isEmergencyKeyCombination(
        keyCode: UInt16,
        modifierFlags: NSEvent.ModifierFlags,
        bothShiftsPressed: Bool
    ) -> Bool {
        // Cmd + L 키이고, 양쪽 Shift가 모두 눌린 상태
        return keyCode == Self.lKeyCode &&
               modifierFlags.contains(.command) &&
               modifierFlags.contains(.shift) &&
               bothShiftsPressed
    }

    // MARK: - Private Methods

    /// 이벤트 처리
    private func handleEvent(_ event: NSEvent) -> NSEvent? {
        switch event.type {
        case .flagsChanged:
            updateShiftState(event)
            return event

        case .keyDown:
            if isEmergencyKeyCombination(
                keyCode: event.keyCode,
                modifierFlags: event.modifierFlags,
                bothShiftsPressed: leftShiftPressed && rightShiftPressed
            ) {
                onEscape?()
                return nil // 이벤트 소비
            }
            return event

        default:
            return event
        }
    }

    /// Shift 키 상태 업데이트
    private func updateShiftState(_ event: NSEvent) {
        let keyCode = event.keyCode
        let shiftPressed = event.modifierFlags.contains(.shift)

        if keyCode == Self.leftShiftKeyCode {
            leftShiftPressed = shiftPressed
        } else if keyCode == Self.rightShiftKeyCode {
            rightShiftPressed = shiftPressed
        }
    }
}
