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

    // MARK: - ViewModels

    private(set) lazy var shieldViewModel: ShieldViewModel = {
        let viewModel = ShieldViewModel()
        viewModel.onUnlockSuccess = { [weak self] in
            self?.stopLock()
        }
        return viewModel
    }()

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

        appState.isLocked = true
        appState.connectedScreens = shieldWindowController.shieldCount
    }

    /// 화면 잠금 해제
    func stopLock() {
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
        shieldViewModel.clearError()
    }

    // MARK: - State Accessors

    var isLocked: Bool {
        appState.isLocked
    }

    var isAwake: Bool {
        appState.isAwake
    }
}
