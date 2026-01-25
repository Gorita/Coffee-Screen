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

    // MARK: - Public Methods

    /// 잠금 해제 시도
    /// Phase 4에서 AuthManager와 연동
    func attemptUnlock() {
        // TODO: Phase 4에서 구현
        isAuthenticating = true
    }

    /// 에러 메시지 초기화
    func clearError() {
        authError = nil
    }
}
