import AppKit

/// 키오스크 모드를 관리하는 컨트롤러
/// NSApplication.PresentationOptions를 사용하여 UI 접근 제한
@MainActor
final class KioskEnforcer {

    // MARK: - Properties

    /// 키오스크 모드 활성화 전 옵션 (복구용)
    private var previousOptions: NSApplication.PresentationOptions = []

    /// 키오스크 모드 활성화 전 활성화 정책 (복구용)
    private var previousActivationPolicy: NSApplication.ActivationPolicy = .regular

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

        // 현재 옵션/정책 저장 (복구용)
        previousOptions = NSApp.presentationOptions
        previousActivationPolicy = NSApp.activationPolicy()

        // 잠금 동안 .accessory 정책으로 전환.
        // .regular 정책에서는 보조/외부 디스플레이의 borderless shield 윈도우가
        // 합성되지 않아 확장 모드에서 두 번째 모니터가 안 덮이는 문제가 있다.
        // .accessory로 전환하면 모든 디스플레이가 정상적으로 덮인다.
        NSApp.setActivationPolicy(.accessory)

        // 키오스크 옵션 적용
        NSApp.presentationOptions = kioskOptions

        // 앱을 최상위로 강제 활성화
        NSApp.activate(ignoringOtherApps: true)

        // 참고: 마우스 커서는 숨기지 않음
        // 사용자가 잠금 해제 버튼을 클릭해야 하므로 커서가 필요함

        isLocked = true
    }

    /// 키오스크 모드 해제 (UI 잠금 해제)
    func unlockUI() {
        guard isLocked else { return }

        // 이전 옵션으로 복구
        NSApp.presentationOptions = previousOptions

        // 이전 활성화 정책으로 복구
        NSApp.setActivationPolicy(previousActivationPolicy)

        isLocked = false
    }
}
