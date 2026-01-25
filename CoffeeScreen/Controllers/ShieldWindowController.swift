import AppKit
import SwiftUI

/// 다중 모니터 Shield 윈도우를 관리하는 컨트롤러
@MainActor
final class ShieldWindowController {

    // MARK: - Properties

    /// 생성된 Shield 윈도우 목록
    private var shieldWindows: [ShieldWindow] = []

    /// 모니터 변경 감지 옵저버 (nonisolated access를 위해 별도 저장)
    private nonisolated(unsafe) var screenObserver: NSObjectProtocol?

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

        for screen in NSScreen.screens {
            let window = createShieldWindow(for: screen, with: viewModel)
            window.orderFrontRegardless()
            shieldWindows.append(window)
        }
    }

    /// 모든 Shield 윈도우 닫기
    func hideShields() {
        shieldWindows.forEach { $0.close() }
        shieldWindows.removeAll()
        currentViewModel = nil
    }

    /// 모든 Shield 윈도우를 최상위로 가져오기
    func bringToFront() {
        shieldWindows.forEach { window in
            window.orderFrontRegardless()
            window.makeKeyAndOrderFront(nil)
        }
    }


    // MARK: - Private Methods

    /// 특정 화면에 대한 Shield 윈도우 생성
    private func createShieldWindow(for screen: NSScreen, with viewModel: ShieldViewModel) -> ShieldWindow {
        let window = ShieldWindow(screen: screen)

        // SwiftUI 뷰 연결
        let shieldView = ShieldView(viewModel: viewModel)
        window.setContent(shieldView)

        return window
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

    /// 모니터 변경 처리
    private func handleScreenChange() {
        guard isShowing, let viewModel = currentViewModel else { return }

        // 기존 윈도우 닫기
        shieldWindows.forEach { $0.close() }
        shieldWindows.removeAll()

        // 새로운 화면 구성으로 재생성
        for screen in NSScreen.screens {
            let window = createShieldWindow(for: screen, with: viewModel)
            window.orderFrontRegardless()
            shieldWindows.append(window)
        }
    }
}
