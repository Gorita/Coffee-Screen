import AppKit
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

    // MARK: - Key Event Handler

    private var keyMonitor: Any?

    /// 키보드 이벤트 모니터링 시작 (Enter 키 누름 감지)
    func setupKeyMonitor() {
        guard keyMonitor == nil else { return }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }
            // Return(36) or Keypad Enter(76)
            if event.keyCode == 36 || event.keyCode == 76 {
                Task { @MainActor in
                    self.handleEnterKeyPress()
                }
                return nil
            }
            return event
        }
    }

    /// 키보드 이벤트 모니터링 해제
    func removeKeyMonitor() {
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
    }

    /// Enter 키 입력 시 동작 처리 (Touch ID 모드에서도 즉시 PIN 입력 모드로 전환)
    func handleEnterKeyPress() {
        if authMode == .touchID {
            showPINInputIfAvailable()
        } else if authMode == .pin {
            if !pinInput.isEmpty {
                attemptPINUnlock()
            }
        }
    }

    // MARK: - Initialization

    init(authManager: AuthManager = AuthManager(), pinManager: PINManager = .shared) {
        self.authManager = authManager
        self.pinManager = pinManager
    }

    deinit {
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
        }
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
            NSApp.activate(ignoringOtherApps: true)
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

    /// Mac 종료 시도
    func shutdownMac() {
        let alert = NSAlert()
        
        let isKorean = Locale.current.language.languageCode?.identifier == "ko"
        alert.messageText = isKorean ? "시스템 종료" : "Shut Down System"
        alert.informativeText = isKorean 
            ? "정말로 Mac을 종료하시겠습니까? 저장하지 않은 작업이 모두 손실될 수 있습니다." 
            : "Are you sure you want to shut down your Mac? You might lose unsaved work."
        alert.alertStyle = .warning
        alert.addButton(withTitle: isKorean ? "종료" : "Shut Down")
        alert.addButton(withTitle: isKorean ? "취소" : "Cancel")
        
        NSApp.activate(ignoringOtherApps: true)
        
        if alert.runModal() == .alertFirstButtonReturn {
            let source = "tell application \"System Events\" to shut down"
            if let script = NSAppleScript(source: source) {
                var error: NSDictionary?
                script.executeAndReturnError(&error)
            }
        }
    }
}
