import SwiftUI

/// 유저가 맞춤 설정한 잠금 화면 (Shield 뷰)
struct ShieldView: View {
    @ObservedObject var viewModel: ShieldViewModel
    var isMainScreen: Bool = true

    @ObservedObject private var settingsManager = LockScreenSettingsManager.shared
    @ObservedObject private var bulletinServer = BulletinSocketServer.shared

    @State private var currentTime = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let pixelFont = "Silkscreen-Regular"

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 1. 커스텀 배경 레이어 (화면 크기에 맞춰 완벽히 래핑 & clipped 처리)
                backgroundLayer(size: geometry.size)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()

                // 2. 추가 스티커 레이어
                stickersLayer

                // 3. 잠금 해제 UI (메인 스크린에만 유저 설정에 따른 위치/스타일로 오버레이 렌더링)
                if isMainScreen {
                    unlockWindowOverlay
                }

                // 4. 커스텀 시계 & 메세지 위젯 레이어 (최상단 Z-Index 배치로 절대 가려지지 않음)
                widgetsLayer

                // 5. 알림판 레이어 (최상단)
                bulletinBoardLayer
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
        }
        .ignoresSafeArea()
        .onReceive(timer) { input in
            currentTime = input
        }
    }

    // MARK: - Background Subviews

    @ViewBuilder
    private func backgroundLayer(size: CGSize) -> some View {
        let layout = settingsManager.layout
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
                } else if let nsImage = settingsManager.loadImage(from: bgPath) {
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

    // MARK: - Sticker Subviews

    private var stickersLayer: some View {
        ZStack {
            ForEach(settingsManager.layout.stickers) { sticker in
                Group {
                    if let iconName = sticker.systemIconName {
                        Image(systemName: iconName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundStyle(Color.white)
                            .shadow(color: .black.opacity(0.6), radius: 6, x: 0, y: 3)
                    } else if let path = sticker.imagePath,
                              let nsImage = settingsManager.loadImage(from: path) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                }
                .frame(width: 100 * sticker.scale, height: 100 * sticker.scale)
                .rotationEffect(.degrees(sticker.rotation))
                .offset(x: sticker.x, y: sticker.y)
            }
        }
    }

    // MARK: - Unlock Window Overlay Subviews

    private var unlockWindowOverlay: some View {
        let config = settingsManager.layout.unlockWindowConfig

        return VStack {
            Spacer()
            UnlockView(viewModel: viewModel)
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

    // MARK: - Widget Subviews (최상단 노출)

    private var widgetsLayer: some View {
        ZStack {
            // 시계 위젯
            if settingsManager.layout.clockConfig.isEnabled {
                Text(formattedTime)
                    .font(.custom(pixelFont, size: settingsManager.layout.clockConfig.fontSize))
                    .foregroundStyle(settingsManager.layout.clockConfig.fontColor)
                    .shadow(color: .black.opacity(0.8), radius: 6, x: 0, y: 3)
                    .offset(x: settingsManager.layout.clockConfig.x, y: settingsManager.layout.clockConfig.y)
            }

            // 안내 메시지 위젯 (커스텀 문구 적용)
            if settingsManager.layout.infoMessageConfig.isEnabled {
                let textToDisplay = (settingsManager.layout.infoMessageConfig.text?.isEmpty == false) 
                    ? settingsManager.layout.infoMessageConfig.text! 
                    : String(localized: "Shield.Message", defaultValue: "System Protected by Coffee-Screen")
                Text(textToDisplay)
                    .font(.custom(pixelFont, size: settingsManager.layout.infoMessageConfig.fontSize))
                    .foregroundStyle(settingsManager.layout.infoMessageConfig.fontColor)
                    .shadow(color: .black.opacity(0.8), radius: 4, x: 0, y: 2)
                    .offset(x: settingsManager.layout.infoMessageConfig.x, y: settingsManager.layout.infoMessageConfig.y)
            }
        }
    }

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: currentTime)
    }
}

#Preview {
    ShieldView(viewModel: ShieldViewModel())
}

// MARK: - 알림판 렌더링

extension ShieldView {

    @ViewBuilder
    var bulletinBoardLayer: some View {
        let cfg = settingsManager.layout.bulletinBoardConfig
        if cfg.isEnabled && !bulletinServer.messages.isEmpty {
            switch cfg.displayStyle {
            case .alert:     alertStyleLayer(cfg: cfg)
            case .terminal:  terminalStyleLayer(cfg: cfg)
            case .pixelText: pixelTextStyleLayer(cfg: cfg)
            }
        }
    }

    // MARK: Alert 스타일 — 우상단 슬라이드인 카드 스택
    @ViewBuilder
    private func alertStyleLayer(cfg: BulletinBoardConfig) -> some View {
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
    }

    // MARK: Terminal 스타일 — 다크 로그 창
    @ViewBuilder
    private func terminalStyleLayer(cfg: BulletinBoardConfig) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // 터미널 타이틀 바
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

            // 로그 내용
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
    }

    // MARK: Pixel Text 스타일 — 픽셀 폰트 텍스트 오버레이
    @ViewBuilder
    private func pixelTextStyleLayer(cfg: BulletinBoardConfig) -> some View {
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

    private func timeString(from date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f.string(from: date)
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

// MARK: - Alert 카드 뷰

struct AlertCard: View {
    let message: BulletinMessage

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // 레벨 색상 바
            RoundedRectangle(cornerRadius: 2)
                .fill(message.level.color)
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Image(systemName: message.level.iconName)
                        .font(.system(size: 11))
                        .foregroundStyle(message.level.color)
                    Text(levelLabel(message.level))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(message.level.color)
                    Spacer()
                    Text(message.timestamp, style: .time)
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.4))
                }
                Text(message.text)
                    .font(.system(size: 12))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(3)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: 340, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(hex: "#1C1C1E") ?? Color.black)
                .opacity(0.92)
        )
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(.white.opacity(0.12), lineWidth: 1))
        .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 4)
    }

    private func levelLabel(_ level: BulletinMessageLevel) -> String {
        switch level {
        case .info:    return "INFO"
        case .success: return "SUCCESS"
        case .warning: return "WARNING"
        case .error:   return "ERROR"
        }
    }
}
