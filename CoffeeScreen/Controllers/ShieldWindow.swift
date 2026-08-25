import AppKit
import SwiftUI

/// 화면을 덮는 Shield 윈도우
/// 다중 모니터 및 독립 Space 환경에서 WindowServer가 100% 렌더링하고
/// 포커스 이동 시에도 숨겨지지 않도록 스크린세이버 레벨과 완벽한 플래그를 적용합니다.
final class ShieldWindow: NSWindow {

    // MARK: - Initialization

    init(screen: NSScreen) {
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        configureWindow()
    }

    // MARK: - Configuration

    private func configureWindow() {
        // 최상위 레벨: macOS 공식 스크린세이버 레벨로 설정하여 모든 모니터의 일반 창을 완벽 차단
        level = .screenSaver

        // 검은 배경 및 버퍼 공유 차단 (각 디스플레이별 독립 프레임버퍼 보장)
        backgroundColor = .black
        isOpaque = true
        hasShadow = false
        sharingType = .none

        // 포커스가 다른 앱이나 모니터로 이동해도 잠금 창이 절대 숨겨지지 않음
        hidesOnDeactivate = false

        // 마우스 이벤트를 잠금 창이 직접 수신하여 데스크탑으로 클릭 유출 방지
        ignoresMouseEvents = false

        // 다크 모드 고정
        appearance = NSAppearance(named: .darkAqua)

        // 모든 Space와 보조 디스플레이에서 위치 고정 및 렌더링 보장
        collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary,
            .ignoresCycle
        ]

        // 릴리즈 시 자동 해제 방지
        isReleasedWhenClosed = false
    }

    // MARK: - NSWindow Overrides

    /// borderless 윈도우가 키 윈도우가 될 수 있도록 허용
    override var canBecomeKey: Bool {
        return true
    }

    /// borderless 윈도우가 메인 윈도우가 될 수 있도록 허용
    override var canBecomeMain: Bool {
        return true
    }

    // MARK: - Content Setup

    /// SwiftUI 뷰를 윈도우에 설정
    func setContent<Content: View>(_ content: Content) {
        contentView = NSHostingView(rootView: content)
    }
}
