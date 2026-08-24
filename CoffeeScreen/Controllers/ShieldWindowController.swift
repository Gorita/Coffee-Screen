import AppKit
import SwiftUI

/// 다중 모니터 Shield 윈도우를 관리하는 컨트롤러
/// WindowServer가 보조 디스플레이를 누락하지 않도록
/// 주 모니터 윈도우와의 부모-자식(Child Window) 계층 결합 및 강제 렌더링을 수행합니다.
@MainActor
final class ShieldWindowController {

    // MARK: - Properties

    /// displayID → Shield 윈도우 매핑
    private var shieldWindows: [CGDirectDisplayID: ShieldWindow] = [:]

    /// 주 모니터의 Shield 윈도우 (자식 윈도우 결합의 부모 기준점)
    private var mainShieldWindow: ShieldWindow?

    /// 모니터 변경 감지 옵저버 (nonisolated access를 위해 별도 저장)
    private nonisolated(unsafe) var screenObserver: NSObjectProtocol?

    /// 잠금 중 화면 구성을 주기적으로 재확인하는 타이머
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

        // 잠금 화면 실행 순간 기존 이전 알림판 메시지 자동 청소
        BulletinSocketServer.shared.clearMessages()

        currentViewModel = viewModel

        // Enter 키 누름 감지 키 모니터 활성화 (Touch ID ➔ PIN 즉시 전환)
        viewModel.setupKeyMonitor()

        // 현재 화면 구성으로 쉴드 구성
        syncShields()

        // 잠금 동안 화면 변화를 계속 추적하도록 폴링 시작
        startPolling()
    }

    /// 모든 Shield 윈도우 닫기
    func hideShields() {
        stopPolling()
        currentViewModel?.removeKeyMonitor()

        // 부모-자식 계층 분리 후 닫기
        if let main = mainShieldWindow {
            for child in main.childWindows ?? [] {
                main.removeChildWindow(child)
            }
        }
        mainShieldWindow = nil

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
            if let main = mainShieldWindow, window != main {
                main.removeChildWindow(window)
            }
            window.close()
            shieldWindows.removeValue(forKey: id)
        }

        // 2. 주 모니터(Main Screen) 윈도우 먼저 생성/배치
        let mainScreen = NSScreen.main ?? currentScreens.first
        if let mainScreen, let mainID = mainScreen.displayID {
            let mainWindow: ShieldWindow
            if let existing = shieldWindows[mainID] {
                existing.setFrame(mainScreen.frame, display: true)
                mainWindow = existing
            } else {
                mainWindow = createShieldWindow(for: mainScreen, with: viewModel)
                shieldWindows[mainID] = mainWindow
            }
            mainShieldWindow = mainWindow
            mainWindow.makeKeyAndOrderFront(nil)
            mainWindow.orderFrontRegardless()
            mainWindow.displayIfNeeded()
        }

        // 3. 보조 모니터(Secondary Screens) 윈도우 생성 및 부모 윈도우 결합
        for screen in currentScreens where screen != mainScreen {
            guard let id = screen.displayID else { continue }

            let secondaryWindow: ShieldWindow
            if let existing = shieldWindows[id] {
                existing.setFrame(screen.frame, display: true)
                secondaryWindow = existing
            } else {
                secondaryWindow = createShieldWindow(for: screen, with: viewModel)
                shieldWindows[id] = secondaryWindow
            }

            // WindowServer가 보조 디스플레이 렌더링을 생략하지 않도록 부모-자식 결합
            if let parent = mainShieldWindow, !(parent.childWindows ?? []).contains(secondaryWindow) {
                parent.addChildWindow(secondaryWindow, ordered: .above)
            }

            secondaryWindow.orderFrontRegardless()
            secondaryWindow.displayIfNeeded()
        }

        // 앱을 최상위로 활성화
        NSApp.activate(ignoringOtherApps: true)
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
