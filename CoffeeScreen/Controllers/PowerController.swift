import Foundation
import IOKit.pwr_mgt

/// 시스템 수면 방지를 관리하는 컨트롤러
/// IOKit Power Assertion을 사용하여 CPU/Network 활성 상태 유지
final class PowerController {

    // MARK: - Properties

    private var assertionID: IOPMAssertionID = 0

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

        let reason = "Coffee-Screen: Screen lock active - preventing sleep" as CFString
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason,
            &assertionID
        )

        if result == kIOReturnSuccess {
            isActive = true
            return .success(())
        } else {
            return .failure(.assertionCreationFailed)
        }
    }

    /// 시스템 수면 방지 해제
    func stopAwake() {
        guard assertionID != 0 else {
            isActive = false
            return
        }

        IOPMAssertionRelease(assertionID)
        assertionID = 0
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
