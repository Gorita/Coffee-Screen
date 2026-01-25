import Foundation
import LocalAuthentication

/// 인증 에러 타입
enum AuthError: Error, Equatable, LocalizedError {
    /// 사용자가 인증을 취소함
    case cancelled
    /// 인증 실패 (에러 메시지 포함)
    case failed(String)
    /// 인증 기능 사용 불가
    case notAvailable

    var errorDescription: String? {
        switch self {
        case .cancelled:
            return String(localized: "error.auth.cancelled")
        case .failed(let message):
            return message
        case .notAvailable:
            return String(localized: "error.auth.notAvailable")
        }
    }
}

/// Touch ID / 비밀번호 인증 관리자
final class AuthManager: @unchecked Sendable {

    // MARK: - Properties

    /// LAContext 생성 팩토리 (테스트용 주입 가능)
    private let contextFactory: () -> LAContext

    // MARK: - Initialization

    init(contextFactory: @escaping () -> LAContext = { LAContext() }) {
        self.contextFactory = contextFactory
    }

    // MARK: - Public Methods

    /// 인증 가능 여부 확인
    /// - Returns: Touch ID 또는 비밀번호 인증이 가능한지 여부
    func canAuthenticate() -> Bool {
        let context = contextFactory()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    }

    /// 인증 수행
    /// - Parameter reason: 인증 요청 이유 (사용자에게 표시)
    /// - Returns: 인증 결과 (성공 시 true, 실패 시 AuthError)
    func authenticate(reason: String) async -> Result<Bool, AuthError> {
        let context = contextFactory()
        var error: NSError?

        // 인증 가능 여부 확인
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            return .failure(.notAvailable)
        }

        // 인증 이유가 비어있으면 기본값 사용
        let authReason = reason.isEmpty ? Constants.Strings.unlockReason : reason

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: authReason
            )
            return .success(success)
        } catch let laError as LAError {
            return .failure(mapLAError(laError))
        } catch {
            return .failure(.failed(error.localizedDescription))
        }
    }

    // MARK: - Private Methods

    /// LAError를 AuthError로 변환
    private func mapLAError(_ error: LAError) -> AuthError {
        switch error.code {
        case .userCancel, .systemCancel, .appCancel:
            return .cancelled
        case .biometryNotAvailable, .biometryNotEnrolled, .passcodeNotSet:
            return .notAvailable
        case .authenticationFailed:
            return .failed(Constants.Strings.authFailed)
        default:
            return .failed(error.localizedDescription)
        }
    }
}
