import AppKit
import SwiftUI

/// 키 입력 및 마우스 클릭/드래그 이벤트를 100% 수용하는 커스텀 무테두리 윈도우
final class BorderlessInteractiveWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

/// 전체 화면 라이브 프리뷰 윈도우 및 플로팅 컨트롤러 패널을 총괄하는 컨트롤러
@MainActor
final class LockScreenEditorWindowController: NSObject, ObservableObject, NSWindowDelegate {
    static let shared = LockScreenEditorWindowController()

    @Published var isEditing: Bool = false
    @Published var draftLayout: LockScreenLayout = LockScreenLayout()

    private var previewWindow: BorderlessInteractiveWindow?
    private var floatingPanel: NSPanel?

    private override init() {
        super.init()
    }

    /// 라이브 프리뷰 에디터 시작
    func startEditing() {
        guard !isEditing else { return }

        print("[DEBUG][LockScreenEditorWindowController] Starting Live Full-Screen Editor...")
        self.draftLayout = LockScreenSettingsManager.shared.layout
        self.isEditing = true

        setupPreviewWindow()
        setupFloatingPanel()
    }

    /// 에디터 종료 (저장 또는 취소 후 윈도우 정리)
    func stopEditing(save: Bool) {
        guard isEditing else { return }

        if save {
            print("[DEBUG][LockScreenEditorWindowController] Saving draft layout to settingsManager...")
            // 유저가 최종 Save를 눌렀을 때만 커스텀 이미지를 Recent Image Library에 수록
            if draftLayout.backgroundType == .customImage, let savedPath = draftLayout.backgroundImagePath, !savedPath.isEmpty {
                var recent = draftLayout.recentImagePaths
                let targetFileName = URL(fileURLWithPath: savedPath).lastPathComponent
                let targetBaseName = URL(fileURLWithPath: savedPath).deletingPathExtension().lastPathComponent
                recent.removeAll { path in
                    let currentFileName = URL(fileURLWithPath: path).lastPathComponent
                    let currentBaseName = URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent
                    return path == savedPath || currentFileName == targetFileName || currentBaseName == targetBaseName
                }
                recent.insert(savedPath, at: 0)
                if recent.count > 6 {
                    recent = Array(recent.prefix(6))
                }
                draftLayout.recentImagePaths = recent
            }
            LockScreenSettingsManager.shared.layout = draftLayout
            LockScreenSettingsManager.shared.saveLayout()
        } else {
            print("[DEBUG][LockScreenEditorWindowController] Discarding draft layout changes...")
        }

        previewWindow?.orderOut(nil)
        previewWindow = nil

        floatingPanel?.delegate = nil
        floatingPanel?.orderOut(nil)
        floatingPanel = nil

        self.isEditing = false
    }

    // MARK: - Window Setup Helpers

    private func setupPreviewWindow() {
        guard let mainScreen = NSScreen.main else { return }

        let window = BorderlessInteractiveWindow(
            contentRect: mainScreen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.level = NSWindow.Level(Int(CGWindowLevelForKey(.floatingWindow)) - 1)
        window.backgroundColor = .black
        window.isOpaque = true
        window.hasShadow = false
        window.ignoresMouseEvents = false // 마우스 제스처 이벤트 수용
        window.acceptsMouseMovedEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let liveView = LiveShieldPreviewView(editorController: self)
        window.contentView = NSHostingView(rootView: liveView)
        window.setFrame(mainScreen.frame, display: true)
        window.orderFront(nil)

        self.previewWindow = window
    }

    private func setupFloatingPanel() {
        let panelWidth: CGFloat = 340
        let panelHeight: CGFloat = 580
        let paddingRight: CGFloat = 40

        guard let mainScreen = NSScreen.main else { return }
        let screenFrame = mainScreen.frame
        let panelRect = NSRect(
            x: screenFrame.maxX - panelWidth - paddingRight,
            y: screenFrame.midY - (panelHeight / 2.0),
            width: panelWidth,
            height: panelHeight
        )

        let panel = NSPanel(
            contentRect: panelRect,
            styleMask: [.titled, .closable, .utilityWindow, .nonactivatingPanel, .hudWindow],
            backing: .buffered,
            defer: false
        )

        panel.title = "Lock Screen Customizer"
        panel.level = .floating
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false
        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.delegate = self

        let controlView = FloatingControlPanelView(editorController: self)
        panel.contentView = NSHostingView(rootView: controlView)
        panel.makeKeyAndOrderFront(nil)

        self.floatingPanel = panel
    }

    // MARK: - NSWindowDelegate
    nonisolated func windowWillClose(_ notification: Notification) {
        Task { @MainActor in
            print("[DEBUG][LockScreenEditorWindowController] Floating panel window closed by user. Closing editor...")
            LockScreenEditorWindowController.shared.stopEditing(save: false)
        }
    }
}

/// 라이브 전체 화면 렌더링 뷰 (draftLayout 수신 & 스티커 마우스 직접 드래그앤드롭 지원)
struct LiveShieldPreviewView: View {
    @ObservedObject var editorController: LockScreenEditorWindowController
    @ObservedObject private var bulletinServer = BulletinSocketServer.shared
    @StateObject private var dummyShieldViewModel = ShieldViewModel()
    @State private var currentTime = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let pixelFont = "Silkscreen-Regular"

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 1. 커스텀 배경 레이어
                backgroundLayer(size: geometry.size)

                // 2. 스티커 레이어 (마우스 드래그 최상위 수신 Z-Index: 100)
                stickersLayer
                    .zIndex(100)

                // 3. 중앙 잠금 해제 UI 실물 오버레이 (드래그 이벤트를 차단하지 않음)
                unlockWindowOverlay
                    .allowsHitTesting(false)
                    .zIndex(10)

                // 4. 커스텀 시계 & 메세지 위젯 레이어
                widgetsLayer
                    .allowsHitTesting(false)
                    .zIndex(20)

                // 5. 알림판 레이어 (최상단)
                bulletinBoardPreviewLayer
                    .allowsHitTesting(false)
                    .zIndex(30)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
        }
        .ignoresSafeArea()
        .onReceive(timer) { input in
            currentTime = input
        }
    }

    @ViewBuilder
    private func backgroundLayer(size: CGSize) -> some View {
        let layout = editorController.draftLayout
        switch layout.backgroundType {
        case .solidColor:
            layout.backgroundColor
        case .customImage:
            if let bgPath = layout.backgroundImagePath {
                let isGIF = bgPath.lowercased().hasSuffix(".gif")
                if isGIF {
                    AnimatedGIFView(imagePath: bgPath, contentMode: layout.imageContentMode)
                        .scaleEffect(layout.imageScale)
                        .offset(x: layout.imageOffsetX, y: layout.imageOffsetY)
                        .frame(width: size.width, height: size.height)
                        .clipped()
                } else if let nsImage = LockScreenSettingsManager.shared.loadImage(from: bgPath) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: layout.imageContentMode == .fill ? .fill : .fit)
                        .scaleEffect(layout.imageScale)
                        .offset(x: layout.imageOffsetX, y: layout.imageOffsetY)
                        .frame(width: size.width, height: size.height)
                        .clipped()
                } else {
                    Color.black
                }
            } else {
                Color.black
            }
        }
    }

    private var stickersLayer: some View {
        ZStack {
            ForEach($editorController.draftLayout.stickers) { $sticker in
                LiveStickerItemView(sticker: $sticker)
            }
        }
    }

    private var unlockWindowOverlay: some View {
        let config = editorController.draftLayout.unlockWindowConfig

        return VStack {
            Spacer()
            UnlockView(viewModel: dummyShieldViewModel, configOverride: config)
                .padding(32)
                .background(unlockWindowBackground(style: config.style, opacity: config.opacity))
                .shadow(color: config.style == .none ? .clear : .black.opacity(0.5), radius: 20, x: 0, y: 10)
                .offset(x: config.xOffset, y: config.yOffset)
            Spacer()
        }
    }

    @ViewBuilder
    private func unlockWindowBackground(style: UnlockWindowStyle, opacity: Double) -> some View {
        switch style {
        case .glassmorphic:
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(opacity))
                .background(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                )
        case .solidBlack:
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(opacity))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.white.opacity(0.3), lineWidth: 2)
                )
        case .none:
            Color.clear
        }
    }

    private var widgetsLayer: some View {
        ZStack {
            if editorController.draftLayout.clockConfig.isEnabled {
                Text(formattedTime)
                    .font(.custom(pixelFont, size: editorController.draftLayout.clockConfig.fontSize))
                    .foregroundStyle(editorController.draftLayout.clockConfig.fontColor)
                    .shadow(color: .black.opacity(0.8), radius: 6, x: 0, y: 3)
                    .offset(x: editorController.draftLayout.clockConfig.x, y: editorController.draftLayout.clockConfig.y)
            }

            if editorController.draftLayout.infoMessageConfig.isEnabled {
                let textToDisplay = (editorController.draftLayout.infoMessageConfig.text?.isEmpty == false)
                    ? editorController.draftLayout.infoMessageConfig.text!
                    : String(localized: "Shield.Message", defaultValue: "System Protected by Coffee-Screen")
                Text(textToDisplay)
                    .font(.custom(pixelFont, size: editorController.draftLayout.infoMessageConfig.fontSize))
                    .foregroundStyle(editorController.draftLayout.infoMessageConfig.fontColor)
                    .shadow(color: .black.opacity(0.8), radius: 4, x: 0, y: 2)
                    .offset(x: editorController.draftLayout.infoMessageConfig.x, y: editorController.draftLayout.infoMessageConfig.y)
            }
        }
    }

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: currentTime)
    }

    // MARK: - 알림판 프리뷰 레이어

    @ViewBuilder
    var bulletinBoardPreviewLayer: some View {
        let cfg = editorController.draftLayout.bulletinBoardConfig
        if !bulletinServer.messages.isEmpty {
            switch cfg.displayStyle {
            case .alert:
                VStack(alignment: .trailing, spacing: 8) {
                    ForEach(bulletinServer.messages) { msg in
                        AlertCard(message: msg)
                            .fixedSize(horizontal: false, vertical: true)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .opacity
                            ))
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: bulletinServer.messages.map(\.id))

            case .terminal:
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 6) {
                        Circle().fill(Color(hex: "#FF5F57") ?? .red).frame(width: 8, height: 8)
                        Circle().fill(Color(hex: "#FFBD2E") ?? .yellow).frame(width: 8, height: 8)
                        Circle().fill(Color(hex: "#28C840") ?? .green).frame(width: 8, height: 8)
                        Spacer()
                        Text("coffee-screen — 알림판")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.6))
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(hex: "#3A3A3A") ?? .gray)

                    VStack(alignment: .leading, spacing: 3) {
                        ForEach(bulletinServer.messages.reversed()) { msg in
                            HStack(alignment: .top, spacing: 6) {
                                Text(timeString(from: msg.timestamp))
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundStyle(.white.opacity(0.4))
                                Text(levelPrefix(msg.level))
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundStyle(msg.level.color)
                                Text(msg.text)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(.white)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding(10)
                }
                .background(Color.black.opacity(0.85))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(.white.opacity(0.12), lineWidth: 1))
                .frame(maxWidth: 420)
                .padding(20)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: bulletinServer.messages.map(\.id))

            case .pixelText:
                let visibleMessages = Array(bulletinServer.messages.prefix(cfg.maxMessages))
                VStack(spacing: 6) {
                    ForEach(visibleMessages) { msg in
                        Text(msg.text)
                            .font(.custom(pixelFont, size: cfg.fontSize))
                            .foregroundStyle(msg.id == visibleMessages.first?.id ? cfg.fontColor : cfg.fontColor.opacity(0.6))
                            .shadow(color: .black.opacity(0.8), radius: 4, x: 0, y: 2)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .transition(.opacity)
                    }
                }
                .offset(x: cfg.positionX, y: cfg.positionY)
                .animation(.easeInOut(duration: 0.4), value: bulletinServer.messages.map(\.id))
            }
        }
    }

    private func timeString(from date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "HH:mm:ss"; return f.string(from: date)
    }

    private func levelPrefix(_ level: BulletinMessageLevel) -> String {
        switch level {
        case .info:    return "[INFO]"
        case .success: return "[OK]  "
        case .warning: return "[WARN]"
        case .error:   return "[ERR] "
        }
    }
}

/// 스티커 마우스 직접 클릭 & 드래그앤드롭 트래킹 서브뷰 (손바닥 커서 피드백 제공)
struct LiveStickerItemView: View {
    @Binding var sticker: StickerItem
    @State private var isHovered: Bool = false
    @State private var isDragging: Bool = false
    @State private var dragStartLocation: CGPoint? = nil

    var body: some View {
        styledStickerContent
            .frame(width: 120 * sticker.scale, height: 120 * sticker.scale)
            .rotationEffect(.degrees(sticker.rotation))
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isDragging ? Color.yellow.opacity(0.2) : (isHovered ? Color.white.opacity(0.15) : Color.clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(isDragging ? Color.yellow : (isHovered ? Color.white.opacity(0.6) : Color.clear), lineWidth: 2)
            )
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
            if hovering {
                NSCursor.openHand.push()
            } else {
                NSCursor.pop()
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .global)
                .onChanged { value in
                    if !isDragging {
                        isDragging = true
                        dragStartLocation = CGPoint(x: sticker.x, y: sticker.y)
                        NSCursor.closedHand.set()
                    }
                    if let start = dragStartLocation {
                        sticker.x = start.x + value.translation.width
                        sticker.y = start.y + value.translation.height
                    }
                }
                .onEnded { _ in
                    isDragging = false
                    dragStartLocation = nil
                    NSCursor.openHand.set()
                }
        )
        .offset(x: sticker.x, y: sticker.y)
    }

    @ViewBuilder
    private var styledStickerContent: some View {
        switch sticker.style {
        case .whiteBorder:
            rawStickerImage
                .padding(6)
                .background(Color.white)
                .cornerRadius(8)
                .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 4)
        case .clean:
            rawStickerImage
                .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)
        case .polaroid:
            VStack(spacing: 4) {
                rawStickerImage
                    .clipped()
                Spacer(minLength: 0)
            }
            .padding(6)
            .padding(.bottom, 12)
            .background(Color.white)
            .cornerRadius(4)
            .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 5)
        }
    }

    @ViewBuilder
    private var rawStickerImage: some View {
        if let iconName = sticker.systemIconName {
            Image(systemName: iconName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundStyle(Color.white)
                .shadow(color: .black.opacity(0.6), radius: 6, x: 0, y: 3)
        } else if let path = sticker.imagePath,
                  let nsImage = LockScreenSettingsManager.shared.loadImage(from: path) {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            Image(systemName: "photo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundStyle(Color.gray)
        }
    }
}
