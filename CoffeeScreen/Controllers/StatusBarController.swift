import AppKit
import SwiftUI

/// 메뉴바 상태 아이콘을 관리하는 컨트롤러
@MainActor
final class StatusBarController: NSObject, NSMenuDelegate {

    // MARK: - Properties

    private var statusItem: NSStatusItem?
    private var menu: NSMenu?

    // 3개의 이미지 뷰
    private var cupWithSteamView: NSImageView?   // 컵 + 김
    private var cupOnlyView: NSImageView?        // 컵만
    private var cupWithKeyholeView: NSImageView? // 컵 + 열쇠구멍

    /// 잠금/해제 콜백
    var onLockToggle: (() -> Void)?

    /// PIN 설정 콜백
    var onOpenPINSettings: (() -> Void)?

    /// Awake 토글 콜백
    var onAwakeToggle: ((Bool) -> Void)?

    /// 현재 잠금 상태
    private var isLocked: Bool = false

    /// PIN 설정 여부
    private var isPINSet: Bool = false

    /// Awake 상태
    private var isAwake: Bool = false

    /// 아이콘이 회전된 상태인지
    private var isRotated: Bool = false

    // MARK: - Initialization

    override init() {
        super.init()
        // 앱이 완전히 시작된 후 StatusItem 생성
        DispatchQueue.main.async { [weak self] in
            self?.setupStatusItem()
        }
    }

    // MARK: - Public Methods

    /// 상태 업데이트
    func updateStatus(isLocked: Bool, isPINSet: Bool, isAwake: Bool = false) {
        self.isLocked = isLocked
        self.isPINSet = isPINSet
        self.isAwake = isAwake
        updateMenu()
    }

    // MARK: - Private Methods

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        guard let button = statusItem?.button else { return }

        let frame = NSRect(x: 3, y: 3, width: 18, height: 18)

        // 1. 커피컵 + 김 (초기 상태, 보임)
        let steamView = NSImageView(frame: frame)
        steamView.image = createCupWithSteamIcon()
        steamView.image?.isTemplate = true
        steamView.wantsLayer = true
        steamView.alphaValue = 1.0

        // 2. 커피컵만 (회전용, 처음엔 숨김)
        let cupView = NSImageView(frame: frame)
        cupView.image = createCupOnlyIcon()
        cupView.image?.isTemplate = true
        cupView.wantsLayer = true
        cupView.alphaValue = 0.0

        // 3. 커피컵 + 열쇠구멍 (최종 상태, 숨김, 미리 회전)
        // 회전 후 시각적 중심 보정을 위해 x 위치 조정
        let keyholeFrame = NSRect(x: 0, y: 3, width: 18, height: 18)
        let keyholeView = NSImageView(frame: keyholeFrame)
        keyholeView.image = createCupWithKeyholeIcon()
        keyholeView.image?.isTemplate = true
        keyholeView.wantsLayer = true
        keyholeView.alphaValue = 0.0
        keyholeView.frameCenterRotation = -90

        button.addSubview(steamView)
        button.addSubview(cupView)
        button.addSubview(keyholeView)

        self.cupWithSteamView = steamView
        self.cupOnlyView = cupView
        self.cupWithKeyholeView = keyholeView

        setupMenu()
    }

    /// 커피컵 + 김 아이콘 (픽셀아트)
    private func createCupWithSteamIcon() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            NSColor.black.setFill()
            let pixel: CGFloat = 2

            // 컵 몸체
            let bodyPixels: [(Int, Int)] = [
                (1, 1), (2, 1), (3, 1), (4, 1), (5, 1),
                (1, 2), (2, 2), (3, 2), (4, 2), (5, 2),
                (1, 3), (2, 3), (3, 3), (4, 3), (5, 3),
                (1, 4), (2, 4), (3, 4), (4, 4), (5, 4),
                (1, 5), (2, 5), (3, 5), (4, 5), (5, 5),
            ]

            // 손잡이
            let handlePixels: [(Int, Int)] = [
                (6, 2), (7, 2),
                (7, 3),
                (7, 4),
                (6, 5), (7, 5),
            ]

            // 김 (두 줄기가 올라가는 모양)
            let steamPixels: [(Int, Int)] = [
                (2, 6), (3, 7), (2, 8),  // 왼쪽 줄기 (S자)
                (4, 6), (5, 7), (4, 8),  // 오른쪽 줄기 (S자)
            ]

            for (px, py) in bodyPixels + handlePixels + steamPixels {
                let pixelRect = NSRect(x: CGFloat(px) * pixel, y: CGFloat(py) * pixel, width: pixel, height: pixel)
                NSBezierPath(rect: pixelRect).fill()
            }

            return true
        }
        image.isTemplate = true
        return image
    }

    /// 커피컵만 (김, 열쇠구멍 없음)
    private func createCupOnlyIcon() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            NSColor.black.setFill()
            let pixel: CGFloat = 2

            // 컵 몸체
            let bodyPixels: [(Int, Int)] = [
                (1, 1), (2, 1), (3, 1), (4, 1), (5, 1),
                (1, 2), (2, 2), (3, 2), (4, 2), (5, 2),
                (1, 3), (2, 3), (3, 3), (4, 3), (5, 3),
                (1, 4), (2, 4), (3, 4), (4, 4), (5, 4),
                (1, 5), (2, 5), (3, 5), (4, 5), (5, 5),
            ]

            // 손잡이
            let handlePixels: [(Int, Int)] = [
                (6, 2), (7, 2),
                (7, 3),
                (7, 4),
                (6, 5), (7, 5),
            ]

            for (px, py) in bodyPixels + handlePixels {
                let pixelRect = NSRect(x: CGFloat(px) * pixel, y: CGFloat(py) * pixel, width: pixel, height: pixel)
                NSBezierPath(rect: pixelRect).fill()
            }

            return true
        }
        image.isTemplate = true
        return image
    }

    /// 커피컵 + 열쇠구멍 (픽셀아트)
    private func createCupWithKeyholeIcon() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            let pixel: CGFloat = 2

            // 컵 몸체 (열쇠구멍 부분 제외)
            NSColor.black.setFill()

            // -90° 회전 시: 왼쪽(낮은x) → 위, 오른쪽(높은x) → 아래
            // 원형(넓음)을 왼쪽에, 슬롯(좁음)을 오른쪽에 배치
            let bodyPixels: [(Int, Int)] = [
                (1, 1), (2, 1), (3, 1), (4, 1), (5, 1),
                (1, 2), (2, 2),        (4, 2), (5, 2),  // 슬롯 (열 3만 비움)
                (1, 3),               (4, 3), (5, 3),  // 원형 (열 2,3 비움) → 회전 후 위쪽
                (1, 4), (2, 4),        (4, 4), (5, 4),  // 슬롯 (열 3만 비움)
                (1, 5), (2, 5), (3, 5), (4, 5), (5, 5),
            ]

            // 손잡이
            let handlePixels: [(Int, Int)] = [
                (6, 2), (7, 2),
                (7, 3),
                (7, 4),
                (6, 5), (7, 5),
            ]

            for (px, py) in bodyPixels + handlePixels {
                let pixelRect = NSRect(x: CGFloat(px) * pixel, y: CGFloat(py) * pixel, width: pixel, height: pixel)
                NSBezierPath(rect: pixelRect).fill()
            }

            return true
        }
        image.isTemplate = true
        return image
    }

    private func setupMenu() {
        menu = NSMenu()
        menu?.delegate = self
        // 저장된 상태로 메뉴 업데이트
        updateMenu()
        statusItem?.menu = menu
    }

    /// 메뉴가 준비되었는지 확인하고 업데이트
    private func ensureMenuUpdated() {
        // 메뉴가 아직 없으면 나중에 setupMenu에서 처리됨
        guard menu != nil else { return }
        updateMenu()
    }

    private func updateMenu() {
        guard let menu = menu else { return }

        menu.removeAllItems()

        // 현재 PIN 상태 직접 확인
        let currentPINSet = PINManager.shared.isPINSet

        // 잠금/해제 메뉴
        let lockTitle = isLocked
            ? String(localized: "menu.unlock")
            : String(localized: "menu.lock")
        let lockItem = NSMenuItem(
            title: lockTitle,
            action: #selector(toggleLock),
            keyEquivalent: "l"
        )
        lockItem.target = self
        // PIN 미설정 시 잠금 비활성화
        if !isLocked && !currentPINSet {
            lockItem.isEnabled = false
        }
        menu.addItem(lockItem)

        // Awake 메뉴 (잠금 해제 상태에서만)
        if !isLocked {
            let awakeTitle = isAwake
                ? String(localized: "menu.awake.off")
                : String(localized: "menu.awake.on")
            let awakeItem = NSMenuItem(
                title: awakeTitle,
                action: #selector(toggleAwake),
                keyEquivalent: "a"
            )
            awakeItem.target = self
            menu.addItem(awakeItem)
        }

        menu.addItem(NSMenuItem.separator())

        // PIN 설정 메뉴 (잠금 해제 상태에서만)
        if !isLocked {
            let pinItem = NSMenuItem(
                title: String(localized: "menu.pinSettings"),
                action: #selector(openPINSettings),
                keyEquivalent: ""
            )
            pinItem.target = self
            menu.addItem(pinItem)

            menu.addItem(NSMenuItem.separator())
        }

        // 종료 메뉴 (잠금 해제 상태에서만)
        if !isLocked {
            let quitItem = NSMenuItem(
                title: String(localized: "menu.quit"),
                action: #selector(quitApp),
                keyEquivalent: "q"
            )
            quitItem.target = self
            menu.addItem(quitItem)
        }
    }

    // MARK: - Animation

    /// 3단계 아이콘 애니메이션
    private func rotateIcon(toLock: Bool) {
        guard let steamView = cupWithSteamView,
              let cupView = cupOnlyView,
              let keyholeView = cupWithKeyholeView else { return }

        if toLock {
            // === 잠금 애니메이션 (3단계) ===

            // 1단계: 김 있는 컵 → 컵만 (김 사라짐)
            steamView.alphaValue = 0.0
            cupView.alphaValue = 1.0

            // 2단계: 컵 90도 회전 + 위치 이동 (1단계 완료 후)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.25
                    context.allowsImplicitAnimation = true
                    context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                    cupView.frameCenterRotation = -90
                    // 회전하면서 keyholeView 위치(x:0)로 이동
                    var newFrame = cupView.frame
                    newFrame.origin.x = 0
                    cupView.frame = newFrame
                } completionHandler: {
                    // 3단계: 컵 → 열쇠구멍 있는 컵 (회전 완료 후)
                    DispatchQueue.main.async {
                        cupView.alphaValue = 0.0
                        keyholeView.alphaValue = 1.0
                    }
                }
            }
        } else {
            // === 해제 애니메이션 (3단계, 역순) ===

            // 1단계: 열쇠구멍 있는 컵 → 컵만 (keyholeView 위치에서 시작)
            keyholeView.alphaValue = 0.0
            cupView.alphaValue = 1.0
            var startFrame = cupView.frame
            startFrame.origin.x = 0
            cupView.frame = startFrame

            // 2단계: 컵 원래대로 회전 + 위치 복귀 (1단계 완료 후)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.25
                    context.allowsImplicitAnimation = true
                    context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                    cupView.frameCenterRotation = 0
                    // 회전하면서 원래 위치(x:3)로 복귀
                    var newFrame = cupView.frame
                    newFrame.origin.x = 3
                    cupView.frame = newFrame
                } completionHandler: {
                    // 3단계: 컵 → 김 있는 컵 (회전 완료 후)
                    DispatchQueue.main.async {
                        cupView.alphaValue = 0.0
                        steamView.alphaValue = 1.0
                    }
                }
            }
        }

        isRotated = toLock
    }

    // MARK: - NSMenuDelegate

    nonisolated func menuWillOpen(_ menu: NSMenu) {
        Task { @MainActor in
            self.updateMenu()
            self.rotateIcon(toLock: true)
        }
    }

    nonisolated func menuDidClose(_ menu: NSMenu) {
        Task { @MainActor in
            self.rotateIcon(toLock: false)
        }
    }

    // MARK: - Actions

    @objc private func toggleLock() {
        onLockToggle?()
    }

    @objc private func openPINSettings() {
        onOpenPINSettings?()
    }

    @objc private func toggleAwake() {
        let newState = !isAwake
        isAwake = newState
        onAwakeToggle?(newState)
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
