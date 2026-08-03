import AppKit
import SwiftUI

/// 다중 모니터 Shield 윈도우를 관리하는 컨트롤러
@MainActor
final class ShieldWindowController {

    // MARK: - Properties

    /// displayID → Shield 윈도우 매핑
    /// (어느 화면이 이미 덮였는지 추적해서 증분 보충/정리가 가능하도록)
    private var shieldWindows: [CGDirectDisplayID: ShieldWindow] = [:]

    /// 모니터 변경 감지 옵저버 (nonisolated access를 위해 별도 저장)
    private nonisolated(unsafe) var screenObserver: NSObjectProtocol?

    /// 잠금 중 화면 구성을 주기적으로 재확인하는 타이머
    /// (KVM 전환·hot-plug 등으로 didChangeScreenParameters 알림이 누락되는 경우 대비)
    private var pollingTimer: Timer?

    /// 화면 재확인 주기 (초)
    private static let pollingInterval: TimeInterval = 1.5

    /// 현재 사용 중인 ViewModel
    private weak var currentViewModel: ShieldViewModel?

    /// 현재 표시 중인 Shield 윈도우 수
    var shieldCount: Int {
        shieldWindows.count
    }

    /// Shield가 표시 중인지 여부
    var isShowing: Bool {
        !shieldWindows.isEmpty
    }

    // MARK: - Lifecycle

    init() {
        setupScreenObserver()
    }

    deinit {
        // screenObserver는 nonisolated(unsafe)로 선언되어 deinit에서 안전하게 접근 가능
        if let observer = screenObserver {
            NotificationCenter.default.removeObserver(observer)
            screenObserver = nil
        }
    }

    // MARK: - Public Methods

    /// 모든 모니터에 Shield 윈도우 표시
    /// - Parameter viewModel: Shield 화면의 ViewModel
    func showShields(with viewModel: ShieldViewModel) {
        // 이미 표시 중이면 무시
        guard !isShowing else { return }

        currentViewModel = viewModel

        // 현재 화면 구성으로 쉴드 구성
        syncShields()

        // 잠금 동안 화면 변화를 계속 추적하도록 폴링 시작
        startPolling()
    }

    /// 모든 Shield 윈도우 닫기
    func hideShields() {
        stopPolling()
        shieldWindows.values.forEach { $0.close() }
        shieldWindows.removeAll()
        currentViewModel = nil
    }

    // MARK: - Private Methods

    /// 현재 화면 구성과 쉴드 윈도우를 동기화한다.
    /// - 쉴드가 없는 화면에는 윈도우를 추가
    /// - 사라진 화면의 윈도우는 정리
    /// - 남아있는 화면은 frame을 갱신 (arrangement 변경 대비)
    private func syncShields() {
        guard let viewModel = currentViewModel else { return }

        let currentScreens = NSScreen.screens
        let currentIDs = Set(currentScreens.compactMap { $0.displayID })

        // 1. 사라진 화면의 쉴드 정리
        for (id, window) in shieldWindows where !currentIDs.contains(id) {
            window.close()
            shieldWindows.removeValue(forKey: id)
        }

        // 2. 새 화면 추가 / 기존 화면 frame 갱신
        for screen in currentScreens {
            guard let id = screen.displayID else { continue }

            if let existing = shieldWindows[id] {
                existing.setFrame(screen.frame, display: true)
            } else {
                let window = createShieldWindow(for: screen, with: viewModel)
                window.orderFrontRegardless()
                shieldWindows[id] = window
            }
        }
    }

    /// 특정 화면에 대한 Shield 윈도우 생성
    private func createShieldWindow(for screen: NSScreen, with viewModel: ShieldViewModel) -> ShieldWindow {
        let window = ShieldWindow(screen: screen)
        let isMain = (screen == NSScreen.main)

        // SwiftUI 뷰 연결
        let shieldView = ShieldView(viewModel: viewModel, isMainScreen: isMain)
        window.setContent(shieldView)

        return window
    }

    /// 화면 재확인 폴링 시작
    private func startPolling() {
        stopPolling()
        pollingTimer = Timer.scheduledTimer(withTimeInterval: Self.pollingInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.syncShields()
            }
        }
    }

    /// 화면 재확인 폴링 중지
    private func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }

    /// 모니터 변경 감지 설정
    private func setupScreenObserver() {
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            // Task를 사용하여 MainActor 컨텍스트에서 안전하게 실행
            Task { @MainActor in
                self.handleScreenChange()
            }
        }
    }

    /// 모니터 변경 처리 (증분 동기화)
    private func handleScreenChange() {
        guard isShowing else { return }
        syncShields()
    }
}

// MARK: - NSScreen displayID

private extension NSScreen {
    /// 화면의 CoreGraphics displayID (화면 식별용)
    var displayID: CGDirectDisplayID? {
        (deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value
    }
}
