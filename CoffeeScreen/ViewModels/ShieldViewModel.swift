import Foundation
import SwiftUI

/// 인증 모드
enum AuthMode {
    case touchID
    case pin
}

/// Shield 화면의 ViewModel
@MainActor
final class ShieldViewModel: ObservableObject {

    // MARK: - Published Properties

    /// 인증 진행 중 여부
    @Published var isAuthenticating: Bool = false

    /// 인증 에러 메시지
    @Published var authError: String?

    /// 현재 인증 모드
    @Published var authMode: AuthMode = .touchID

    /// PIN 입력값
    @Published var pinInput: String = ""

    /// PIN 입력 중 여부
    @Published var showPINInput: Bool = false

    /// Touch ID 시도 여부 (한 번 시도하면 재시도 불가)
    @Published var hasTouchIDBeenAttempted: Bool = false

    // MARK: - Callbacks

    /// 잠금 해제 성공 시 호출되는 콜백
    var onUnlockSuccess: (() -> Void)?

    /// 인증 시도 완료 시 호출되는 콜백 (성공/실패 무관, 앱 재활성화용)
    var onAuthAttemptCompleted: (() -> Void)?

    // MARK: - Dependencies

    private let authManager: AuthManager
    private let pinManager: PINManager

    // MARK: - Computed Properties

    /// Touch ID 사용 가능 여부
    var isBiometricAvailable: Bool {
        authManager.isBiometricAvailable()
    }

    /// PIN 설정 여부
    var isPINSet: Bool {
        pinManager.isPINSet
    }

    // MARK: - Initialization

    init(authManager: AuthManager = AuthManager(), pinManager: PINManager = .shared) {
        self.authManager = authManager
        self.pinManager = pinManager
    }

    // MARK: - Public Methods

    /// Touch ID로 잠금 해제 시도
    func attemptTouchID() {
        guard !isAuthenticating else { return }

        isAuthenticating = true
        authError = nil
        hasTouchIDBeenAttempted = true

        Task {
            let result = await authManager.authenticate(reason: Constants.Strings.unlockReason)

            isAuthenticating = false

            // 인증 완료 후 앱 재활성화 (성공/실패 무관)
            onAuthAttemptCompleted?()

            switch result {
            case .success(true):
                onUnlockSuccess?()

            case .success(false):
                // Touch ID 실패 - PIN 입력 모드로 전환
                showPINInputIfAvailable()

            case .failure(let error):
                switch error {
                case .cancelled:
                    // 취소 시 PIN 입력 모드로 전환
                    showPINInputIfAvailable()
                case .notAvailable:
                    // Touch ID 사용 불가 - PIN 입력 모드로 전환
                    showPINInputIfAvailable()
                case .failed:
                    // 실패 시 PIN 입력 모드로 전환
                    showPINInputIfAvailable()
                }
            }
        }
    }

    /// PIN으로 잠금 해제 시도
    func attemptPINUnlock() {
        guard !pinInput.isEmpty else { return }

        if pinManager.verifyPIN(pinInput) {
            pinInput = ""
            showPINInput = false
            authError = nil
            onUnlockSuccess?()
        } else {
            authError = String(localized: "error.pin.incorrect")
            pinInput = ""
        }
    }

    /// PIN 입력 모드 표시 (PIN이 설정된 경우에만)
    func showPINInputIfAvailable() {
        if isPINSet {
            authMode = .pin
            showPINInput = true
            authError = nil
            pinInput = ""
        } else {
            authError = String(localized: "error.pin.notSet")
        }
    }

    /// Touch ID 모드로 돌아가기
    func switchToTouchID() {
        authMode = .touchID
        showPINInput = false
        pinInput = ""
        authError = nil
    }

    /// 인증 상태 리셋 (앱 재활성화 시 호출)
    func resetAuthState() {
        // 인증 중이 아니고, Touch ID가 사용 가능하고, 아직 시도하지 않았으면 Touch ID 모드로 리셋
        if !isAuthenticating && isBiometricAvailable && !hasTouchIDBeenAttempted {
            authMode = .touchID
            showPINInput = false
            pinInput = ""
            authError = nil
        }
    }

    /// 에러 메시지 초기화
    func clearError() {
        authError = nil
    }

    /// 전체 상태 초기화 (잠금 해제 시 호출)
    func resetAll() {
        isAuthenticating = false
        authError = nil
        authMode = .touchID
        pinInput = ""
        showPINInput = false
        hasTouchIDBeenAttempted = false
    }
}
