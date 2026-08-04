import SwiftUI

/// 유저가 맞춤 설정한 잠금 화면 (Shield 뷰)
struct ShieldView: View {
    @ObservedObject var viewModel: ShieldViewModel
    var isMainScreen: Bool = true

    @ObservedObject private var settingsManager = LockScreenSettingsManager.shared

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
