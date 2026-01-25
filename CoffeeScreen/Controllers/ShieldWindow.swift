import AppKit
import SwiftUI

/// 화면을 덮는 Shield 윈도우
/// borderless 윈도우이지만 키 윈도우가 될 수 있도록 설정
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
        // 최상위 레벨 (스크린세이버보다 위)
        level = NSWindow.Level(rawValue: Constants.shieldWindowLevel)

        // 검은 배경
        backgroundColor = .black
        isOpaque = true
        hasShadow = false

        // 모든 Space에서 표시
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

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
