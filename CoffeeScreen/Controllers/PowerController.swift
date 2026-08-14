import Foundation
import IOKit.pwr_mgt

/// 시스템 수면 및 화면 꺼짐 방지를 관리하는 컨트롤러
/// 최신 IOKit Power Assertion 및 ProcessInfo Activity를 이중으로 사용하여
/// macOS Sonoma/Sequoia 등 모든 환경에서 안정적인 Keep-Awake를 보장합니다.
final class PowerController {

    // MARK: - Properties

    private var displayAssertionID: IOPMAssertionID = 0
    private var idleAssertionID: IOPMAssertionID = 0
    private var processActivityToken: NSObjectProtocol?

    /// 현재 수면 방지가 활성화되어 있는지 여부
    private(set) var isActive: Bool = false

    // MARK: - Public Methods

    /// 시스템 수면 방지 및 화면 꺼짐 방지 시작
    /// - Returns: 성공 시 .success, 실패 시 .failure(PowerError)
    func startAwake() -> Result<Void, PowerError> {
        // 이미 활성화된 경우 기존 assertion 해제 후 재생성
        if isActive {
            stopAwake()
        }

        let reason = "Coffee-Screen: User requested screen and sleep protection" as CFString
        
        // 1. 디스플레이 꺼짐 방지 (최신 macOS 표준: PreventUserIdleDisplaySleep)
        let displayResult = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason,
            &displayAssertionID
        )

        // 2. 시스템 유휴 잠자기 방지 (최신 macOS 표준: PreventUserIdleSystemSleep)
        let idleResult = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason,
            &idleAssertionID
        )

        // 3. ProcessInfo Activity를 통한 App Nap 및 백그라운드 쓰로틀링 방지 이중 방어
        processActivityToken = ProcessInfo.processInfo.beginActivity(
            options: [.userInitiated, .idleDisplaySleepDisabled, .idleSystemSleepDisabled],
            reason: "Coffee-Screen: Standalone Keep-Awake Process Activity"
        )

        if displayResult == kIOReturnSuccess && idleResult == kIOReturnSuccess {
            isActive = true
            return .success(())
        } else {
            // 하나라도 실패하면 정리 후 실패 반환
            stopAwake()
            return .failure(.assertionCreationFailed)
        }
    }

    /// 시스템 수면 및 화면 꺼짐 방지 해제
    func stopAwake() {
        if displayAssertionID != 0 {
            IOPMAssertionRelease(displayAssertionID)
            displayAssertionID = 0
        }
        
        if idleAssertionID != 0 {
            IOPMAssertionRelease(idleAssertionID)
            idleAssertionID = 0
        }

        if let token = processActivityToken {
            ProcessInfo.processInfo.endActivity(token)
            processActivityToken = nil
        }

        isActive = false
    }

    // MARK: - Deinit

    deinit {
        stopAwake()
    }
}

// MARK: - PowerError

enum PowerError: Error, LocalizedError {
    case assertionCreationFailed
    case assertionReleaseFailed

    var errorDescription: String? {
        switch self {
        case .assertionCreationFailed:
            return "시스템 수면 방지 활성화에 실패했습니다."
        case .assertionReleaseFailed:
            return "시스템 수면 방지 해제에 실패했습니다."
        }
    }
}
