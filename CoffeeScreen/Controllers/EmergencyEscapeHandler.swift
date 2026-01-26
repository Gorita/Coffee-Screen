import AppKit
import Carbon.HIToolbox

/// 비상 탈출 키 조합 핸들러
/// 설정된 키 조합을 감지하여 긴급 잠금 해제
@MainActor
final class EmergencyEscapeHandler {

    // MARK: - Constants

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

    /// 키 조합 관리자
    private let keyCombinationManager: KeyCombinationManager

    // MARK: - Lifecycle

    init(keyCombinationManager: KeyCombinationManager = .shared) {
        self.keyCombinationManager = keyCombinationManager
    }

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
        let configured = keyCombinationManager.currentKeyCombination

        // 키 코드 일치 확인
        guard keyCode == configured.keyCode else { return false }

        // 수정자 키 확인 (Shift 제외, 별도 처리)
        let requiredModifiers = configured.modifierFlags.intersection([.command, .control, .option])
        let eventModifiers = modifierFlags.intersection([.command, .control, .option])
        guard eventModifiers.contains(requiredModifiers) else { return false }

        // Shift 키 확인
        if configured.requiresBothShifts {
            // 양쪽 Shift 필요
            guard modifierFlags.contains(.shift) && bothShiftsPressed else { return false }
        } else if configured.modifierFlags.contains(.shift) {
            // 단일 Shift 필요
            guard modifierFlags.contains(.shift) else { return false }
        }

        return true
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
