import Foundation
import SwiftUI

/// 메인 화면의 ViewModel
@MainActor
final class MainViewModel: ObservableObject {
    @Published var appState = AppState()

    // MARK: - Controllers

    private let powerController = PowerController()
    private let kioskEnforcer = KioskEnforcer()

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
        appState.isLocked = kioskEnforcer.isLocked
    }

    /// 화면 잠금 해제
    func stopLock() {
        // 키오스크 모드 해제
        kioskEnforcer.unlockUI()
        appState.isLocked = false

        // 시스템 수면 방지 해제
        powerController.stopAwake()
        appState.isAwake = false

        // 에러 상태 초기화
        appState.lastError = nil
    }

    // MARK: - State Accessors

    var isLocked: Bool {
        appState.isLocked
    }

    var isAwake: Bool {
        appState.isAwake
    }
}
