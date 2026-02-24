import Foundation
import IOKit.pwr_mgt

/// 시스템 수면 방지를 관리하는 컨트롤러
/// IOKit Power Assertion을 사용하여 CPU/Network 활성 상태 유지
final class PowerController {

    // MARK: - Properties

    private var displayAssertionID: IOPMAssertionID = 0
    private var idleAssertionID: IOPMAssertionID = 0

    /// 현재 수면 방지가 활성화되어 있는지 여부
    private(set) var isActive: Bool = false

    // MARK: - Public Methods

    /// 시스템 수면 방지 시작
    /// - Returns: 성공 시 .success, 실패 시 .failure(PowerError)
    func startAwake() -> Result<Void, PowerError> {
        // 이미 활성화된 경우 기존 assertion 해제 후 재생성
        if isActive {
            stopAwake()
        }

        let reason = "Coffee-Screen: User requested activity protection" as CFString
        
        // 1. 디스플레이 꺼짐 방지 (가장 높은 수준)
        let displayResult = IOPMAssertionCreateWithName(
            kIOPMAssertionTypeNoDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason,
            &displayAssertionID
        )

        // 2. 시스템 유휴 잠자기 방지 (Idle Sleep 방지)
        let idleResult = IOPMAssertionCreateWithName(
            kIOPMAssertionTypeNoIdleSleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason,
            &idleAssertionID
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

    /// 시스템 수면 방지 해제
    func stopAwake() {
        if displayAssertionID != 0 {
            IOPMAssertionRelease(displayAssertionID)
            displayAssertionID = 0
        }
        
        if idleAssertionID != 0 {
            IOPMAssertionRelease(idleAssertionID)
            idleAssertionID = 0
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
