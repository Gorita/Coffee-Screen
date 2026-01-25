import AppKit

/// 키오스크 모드를 관리하는 컨트롤러
/// NSApplication.PresentationOptions를 사용하여 UI 접근 제한
@MainActor
final class KioskEnforcer {

    // MARK: - Properties

    /// 키오스크 모드 활성화 전 옵션 (복구용)
    private var previousOptions: NSApplication.PresentationOptions = []

    /// 현재 키오스크 모드가 활성화되어 있는지 여부
    private(set) var isLocked: Bool = false

    // MARK: - Kiosk Options

    /// 키오스크 모드에서 사용할 옵션
    private var kioskOptions: NSApplication.PresentationOptions {
        [
            .disableForceQuit,           // Cmd+Opt+Esc 비활성화
            .disableProcessSwitching,    // Cmd+Tab 비활성화
            .disableSessionTermination,  // 전원 버튼 메뉴 차단
            .disableAppleMenu,           // 애플 메뉴 차단
            .disableHideApplication,     // Cmd+H 차단
            .hideDock,                   // Dock 숨김
            .hideMenuBar                 // 메뉴바 숨김
        ]
    }

    // MARK: - Public Methods

    /// 키오스크 모드 활성화 (UI 잠금)
    func lockUI() {
        guard !isLocked else { return }

        // 현재 옵션 저장 (복구용)
        previousOptions = NSApp.presentationOptions

        // 키오스크 옵션 적용
        NSApp.presentationOptions = kioskOptions

        // 앱을 최상위로 강제 활성화
        NSApp.activate(ignoringOtherApps: true)

        // 마우스 커서 숨김
        NSCursor.hide()

        isLocked = true
    }

    /// 키오스크 모드 해제 (UI 잠금 해제)
    func unlockUI() {
        guard isLocked else { return }

        // 이전 옵션으로 복구
        NSApp.presentationOptions = previousOptions

        // 마우스 커서 표시
        NSCursor.unhide()

        isLocked = false
    }
}
