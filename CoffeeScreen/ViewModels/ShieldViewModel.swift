import Foundation
import SwiftUI

/// Shield 화면의 ViewModel
@MainActor
final class ShieldViewModel: ObservableObject {

    // MARK: - Published Properties

    /// 인증 진행 중 여부
    @Published var isAuthenticating: Bool = false

    /// 인증 에러 메시지
    @Published var authError: String?

    // MARK: - Callbacks

    /// 잠금 해제 성공 시 호출되는 콜백
    var onUnlockSuccess: (() -> Void)?

    // MARK: - Dependencies

    private let authManager: AuthManager

    // MARK: - Initialization

    init(authManager: AuthManager = AuthManager()) {
        self.authManager = authManager
    }

    // MARK: - Public Methods

    /// 잠금 해제 시도
    func attemptUnlock() {
        guard !isAuthenticating else { return }

        isAuthenticating = true
        authError = nil

        Task {
            let result = await authManager.authenticate(reason: Constants.Strings.unlockReason)

            isAuthenticating = false

            switch result {
            case .success(true):
                onUnlockSuccess?()

            case .success(false):
                authError = Constants.Strings.authFailed

            case .failure(let error):
                // 취소는 에러 표시 안 함
                if case .cancelled = error {
                    return
                }
                authError = error.localizedDescription
            }
        }
    }

    /// 에러 메시지 초기화
    func clearError() {
        authError = nil
    }
}
