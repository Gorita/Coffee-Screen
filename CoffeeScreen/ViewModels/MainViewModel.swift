import AppKit
import Foundation
import SwiftUI

/// 메인 화면의 ViewModel
@MainActor
final class MainViewModel: ObservableObject {
    @Published var appState = AppState()
    @Published var isStandaloneAwake: Bool = false

    // MARK: - Controllers

    private let powerController = PowerController()
    private let kioskEnforcer = KioskEnforcer()
    private let shieldWindowController = ShieldWindowController()
    private let emergencyEscapeHandler = EmergencyEscapeHandler()
    private let statusBarController = StatusBarController()
    private let pinManager = PINManager.shared

    // MARK: - ViewModels

    private(set) lazy var shieldViewModel: ShieldViewModel = {
        let viewModel = ShieldViewModel()
        viewModel.onUnlockSuccess = { [weak self] in
            self?.stopLock()
        }
        return viewModel
    }()

    // MARK: - Initialization

    init() {
        setupEmergencyEscape()
        setupStatusBar()
        observePINChanges()
    }

    /// PIN 변경 알림 구독
    private func observePINChanges() {
        NotificationCenter.default.addObserver(
            forName: PINManager.pinDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateStatusBar()
        }
    }

    // MARK: - Public Methods

    /// 화면 잠금 시작
    func startLock() {
        // PIN 설정 여부 확인
        guard isPINSet else {
            appState.lastError = String(localized: "error.pin.notSet")
            return
        }

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

    /// 독립 Awake 모드 시작 (화면 잠금 없이 수면 방지만)
    func startStandaloneAwake() {
        // 이미 잠금 상태면 무시
        guard !appState.isLocked else { return }

        let result = powerController.startAwake()
        switch result {
        case .success:
            isStandaloneAwake = true
            appState.isAwake = true
        case .failure(let error):
            appState.lastError = error.localizedDescription
            isStandaloneAwake = false
        }
    }

    /// 독립 Awake 모드 해제
    func stopStandaloneAwake() {
        // 잠금 상태면 무시 (잠금 해제 시 자동으로 처리됨)
        guard !appState.isLocked else { return }

        powerController.stopAwake()
        isStandaloneAwake = false
        appState.isAwake = false
    }

    // MARK: - State Accessors

    var isLocked: Bool {
        appState.isLocked
    }

    var isAwake: Bool {
        appState.isAwake
    }

    /// PIN 설정 여부
    var isPINSet: Bool {
        pinManager.isPINSet
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
            NSApp.activate(ignoringOtherApps: true)

            // 메인 윈도우 찾아서 표시
            for window in NSApp.windows where !(window is ShieldWindow) {
                window.makeKeyAndOrderFront(nil)
                return
            }
        }

        // 초기 상태 업데이트
        updateStatusBar()
    }

    /// 상태바 업데이트
    private func updateStatusBar() {
        statusBarController.updateStatus(isLocked: appState.isLocked, isPINSet: isPINSet)
    }
}
