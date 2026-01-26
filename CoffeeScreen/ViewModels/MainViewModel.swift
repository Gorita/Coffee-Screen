import AppKit
import Foundation
import SwiftUI

/// 메인 화면의 ViewModel
@MainActor
final class MainViewModel: ObservableObject {
    @Published var appState = AppState()

    // MARK: - Controllers

    private let powerController = PowerController()
    private let kioskEnforcer = KioskEnforcer()
    private let shieldWindowController = ShieldWindowController()
    private let emergencyEscapeHandler = EmergencyEscapeHandler()
    private let statusBarController = StatusBarController()

    // MARK: - ViewModels

    private(set) lazy var shieldViewModel: ShieldViewModel = {
        let viewModel = ShieldViewModel()
        viewModel.onUnlockSuccess = { [weak self] in
            self?.stopLock()
        }
        viewModel.onAuthAttemptCompleted = { [weak self] in
            self?.reactivateKiosk()
        }
        return viewModel
    }()

    // MARK: - Initialization

    init() {
        setupEmergencyEscape()
        setupStatusBar()
    }

    // MARK: - Public Methods

    /// 화면 잠금 시작
    func startLock() {
        // 시스템 수면 방지 활성화
        let powerResult = powerController.startAwake()
        switch powerResult {
        case .success:
            appState.isAwake = true
        case .failure(let error):
            appState.lastError = error.localizedDescription
        }

        // 키오스크 모드 활성화
        kioskEnforcer.lockUI()

        // Shield 윈도우 표시
        shieldWindowController.showShields(with: shieldViewModel)

        // 비상 탈출 키 모니터링 시작
        emergencyEscapeHandler.start()

        appState.isLocked = true
        appState.connectedScreens = shieldWindowController.shieldCount

        // 상태바 업데이트
        updateStatusBar()
    }

    /// 화면 잠금 해제
    func stopLock() {
        // 비상 탈출 키 모니터링 중지
        emergencyEscapeHandler.stop()

        // Shield 윈도우 숨김
        shieldWindowController.hideShields()

        // 키오스크 모드 해제
        kioskEnforcer.unlockUI()

        // 시스템 수면 방지 해제
        powerController.stopAwake()

        // 상태 초기화
        appState.isLocked = false
        appState.isAwake = false
        appState.lastError = nil
        shieldViewModel.resetAll()

        // 상태바 업데이트
        updateStatusBar()
    }

    // MARK: - State Accessors

    var isLocked: Bool {
        appState.isLocked
    }

    var isAwake: Bool {
        appState.isAwake
    }

    // MARK: - Private Methods

    /// 비상 탈출 핸들러 설정
    private func setupEmergencyEscape() {
        emergencyEscapeHandler.onEscape = { [weak self] in
            guard let self, self.appState.isLocked else { return }
            self.stopLock()
        }
    }

    /// 상태바 컨트롤러 설정
    private func setupStatusBar() {
        statusBarController.onLockToggle = { [weak self] in
            guard let self else { return }
            if self.appState.isLocked {
                // 잠금 상태에서는 메뉴바로 해제 불가 (인증 필요)
            } else {
                self.startLock()
            }
        }

        statusBarController.onOpenPINSettings = {
            // 메인 윈도우 활성화
            NSApp.activate(ignoringOtherApps: true)
            for window in NSApp.windows {
                if !(window is ShieldWindow) && window.contentView != nil {
                    window.makeKeyAndOrderFront(nil)
                    break
                }
            }
        }
    }

    /// 상태바 업데이트
    private func updateStatusBar() {
        statusBarController.updateStatus(isLocked: appState.isLocked)
    }

    /// 키오스크 모드 재활성화 (Touch ID 인증 후)
    private func reactivateKiosk() {
        guard appState.isLocked else { return }

        // 앱을 최상위로 강제 활성화
        NSApp.activate(ignoringOtherApps: true)

        // Shield 윈도우를 최상위로
        shieldWindowController.bringToFront()

        // 인증 상태 리셋 (Touch ID 다시 사용 가능하도록)
        shieldViewModel.resetAuthState()
    }
}
