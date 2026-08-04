import SwiftUI

/// Unlock UI (UnlockWindowConfig 내부 커스터마이징 실시간 오버라이드 지원)
struct UnlockView: View {
    @ObservedObject var viewModel: ShieldViewModel
    var configOverride: UnlockWindowConfig? = nil

    private let pixelFont = "Silkscreen-Regular"

    private var config: UnlockWindowConfig {
        configOverride ?? LockScreenSettingsManager.shared.layout.unlockWindowConfig
    }

    var body: some View {
        VStack(spacing: 20) {
            // 1. 헤더 아이콘 (None, Custom Image, Symbol)
            headerIconView(config: config)

            // 2. App Title (커스텀 텍스트, 폰트 크기, 색상, 숨기기 연동)
            if config.isTitleVisible && !config.titleText.isEmpty {
                Text(config.titleText)
                    .font(.custom(pixelFont, size: config.titleFontSize))
                    .foregroundStyle(config.titleColor)
            }

            // 3. Info Subtext (커스텀 서브텍스트, 폰트 크기, 색상, 숨기기 연동)
            if config.isSubtextVisible && !config.subtextText.isEmpty {
                Text(config.subtextText)
                    .font(.custom(pixelFont, size: config.subtextFontSize))
                    .foregroundStyle(config.subtextColor)
            }

            if viewModel.showPINInput {
                // PIN input UI
                PINInputView(viewModel: viewModel, configOverride: config)
            } else {
                // Touch ID button
                TouchIDButton(viewModel: viewModel, configOverride: config)
            }

            // Error message
            if let error = viewModel.authError {
                Text(error)
                    .font(.custom(pixelFont, size: 10))
                    .foregroundStyle(.red)
                    .padding(.top, 8)
            }

            // Mode switch button (Use PIN / Use Touch ID 커스텀 연동)
            if config.isModeSwitchButtonVisible {
                if viewModel.showPINInput && viewModel.isBiometricAvailable && !viewModel.hasTouchIDBeenAttempted {
                    Button(action: {
                        viewModel.switchToTouchID()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: config.touchIDStyle.systemIconName)
                            Text(config.useTouchIDText)
                                .font(.custom(pixelFont, size: config.modeSwitchFontSize))
                        }
                        .foregroundStyle(config.modeSwitchColor)
                        .opacity(config.modeSwitchOpacity)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 8)
                } else if viewModel.showPINInput && viewModel.hasTouchIDBeenAttempted {
                    Text("Touch ID unavailable")
                        .font(.custom(pixelFont, size: config.modeSwitchFontSize))
                        .foregroundStyle(config.modeSwitchColor.opacity(0.5))
                        .padding(.top, 8)
                } else if !viewModel.showPINInput && viewModel.isPINSet {
                    Button(action: {
                        viewModel.showPINInputIfAvailable()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "number")
                            Text(config.usePINText)
                                .font(.custom(pixelFont, size: config.modeSwitchFontSize))
                        }
                        .foregroundStyle(config.modeSwitchColor)
                        .opacity(config.modeSwitchOpacity)
                    }
                    .buttonStyle(.plain)
                }
            }

            // 4. Emergency Shutdown Button
            if config.isShutdownButtonVisible {
                Button(action: {
                    viewModel.shutdownMac()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "power")
                        Text(Locale.current.identifier.hasPrefix("ko") ? "Mac 종료" : "Shut Down Mac")
                            .font(.custom(pixelFont, size: 10))
                    }
                    .foregroundStyle(.red.opacity(0.8))
                }
                .buttonStyle(.plain)
                .padding(.top, 12)
            }
        }
        .padding(40)
    }

    @ViewBuilder
    private func headerIconView(config: UnlockWindowConfig) -> some View {
        switch config.headerIcon {
        case .none:
            EmptyView()
        case .customImage:
            if let path = config.headerCustomImagePath,
               let nsImage = LockScreenSettingsManager.shared.loadImage(from: path) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Image(systemName: "lock.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(config.headerIconColor)
            }
        default:
            if let symbol = config.headerIcon.systemIconName {
                Image(systemName: symbol)
                    .font(.system(size: 64))
                    .foregroundStyle(config.headerIconColor)
            }
        }
    }
}

/// Touch ID button (TouchIDStyle, Color, Width, Opacity, Text & Style 연동)
struct TouchIDButton: View {
    @ObservedObject var viewModel: ShieldViewModel
    var configOverride: UnlockWindowConfig? = nil

    private let pixelFont = "Silkscreen-Regular"

    private var config: UnlockWindowConfig {
        configOverride ?? LockScreenSettingsManager.shared.layout.unlockWindowConfig
    }

    var body: some View {
        if !config.isTouchIDVisible {
            EmptyView()
        } else {
            Button(action: {
                viewModel.attemptTouchID()
            }) {
                HStack(spacing: 8) {
                    if viewModel.isAuthenticating {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Image(systemName: config.touchIDStyle.systemIconName)
                    }

                    if !config.touchIDButtonText.trimmingCharacters(in: .whitespaces).isEmpty {
                        Text(config.touchIDButtonText)
                            .font(.custom(pixelFont, size: 12))
                    }
                }
                .foregroundStyle(.white)
                .frame(width: config.touchIDButtonWidth)
                .padding(.vertical, 12)
                .applyCustomButtonStyle(config.touchIDButtonStyle, color: config.touchIDButtonColor)
                .opacity(config.touchIDButtonOpacity)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isAuthenticating)
        }
    }
}

/// PIN input UI (Mask Symbol, Input Box Width/Color/Opacity, Confirm Button Width/Color/Opacity/Text & Style 연동)
struct PINInputView: View {
    @ObservedObject var viewModel: ShieldViewModel
    var configOverride: UnlockWindowConfig? = nil
    @FocusState private var isFocused: Bool

    private let pixelFont = "Silkscreen-Regular"

    private var config: UnlockWindowConfig {
        configOverride ?? LockScreenSettingsManager.shared.layout.unlockWindowConfig
    }

    var body: some View {
        VStack(spacing: 14) {
            // 2번 옵션: 미리 빈 네모 상자를 보여주지 않고, 유저가 입력한 글자 수만큼만 동적으로 심볼 표시
            if !viewModel.pinInput.isEmpty {
                HStack(spacing: 8) {
                    ForEach(0..<viewModel.pinInput.count, id: \.self) { _ in
                        Text(config.pinMaskSymbol.rawValue)
                            .font(.custom(pixelFont, size: 16))
                            .foregroundStyle(Color.yellow)
                            .frame(width: 32, height: 36)
                            .background(config.pinInputBoxColor.opacity(config.pinInputBoxOpacity))
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .strokeBorder(Color.yellow, lineWidth: 1)
                            )
                    }
                }
            }

            // PIN 입력 텍스트 필드
            SecureField("Enter PIN", text: $viewModel.pinInput)
                .font(.custom(pixelFont, size: 14))
                .textFieldStyle(.roundedBorder)
                .frame(width: max(140, config.pinInputBoxWidth))
                .multilineTextAlignment(.center)
                .focused($isFocused)
                .onSubmit {
                    viewModel.attemptPINUnlock()
                }
                .onAppear {
                    NSApp.activate(ignoringOtherApps: true)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        isFocused = true
                    }
                }
                .onChange(of: viewModel.showPINInput) { show in
                    if show {
                        NSApp.activate(ignoringOtherApps: true)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            isFocused = true
                        }
                    }
                }

            // PIN confirm button
            Button(action: {
                viewModel.attemptPINUnlock()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                    if !config.pinConfirmButtonText.trimmingCharacters(in: .whitespaces).isEmpty {
                        Text(config.pinConfirmButtonText)
                            .font(.custom(pixelFont, size: 12))
                    }
                }
                .foregroundStyle(.white)
                .frame(width: config.pinButtonWidth)
                .padding(.vertical, 12)
                .applyPINButtonStyle(config.pinButtonStyle, color: viewModel.pinInput.isEmpty ? Color.gray : config.pinConfirmButtonColor)
                .opacity(config.pinConfirmButtonOpacity)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.pinInput.isEmpty)
        }
    }
}

// Custom Button Styling Modifiers
extension View {
    @ViewBuilder
    func applyCustomButtonStyle(_ style: ButtonStyleType, color: Color) -> some View {
        switch style {
        case .solid:
            self.background(color)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.white.opacity(0.3), lineWidth: 1.5)
                )
        case .outlined:
            self.background(Color.black.opacity(0.3))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(color, lineWidth: 2)
                )
        case .glass:
            self.background(.ultraThinMaterial)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(color.opacity(0.8), lineWidth: 1.5)
                )
        }
    }

    @ViewBuilder
    func applyPINButtonStyle(_ style: PINButtonStyle, color: Color) -> some View {
        switch style {
        case .pixel:
            self.background(color)
                .overlay(
                    Rectangle()
                        .strokeBorder(Color.white.opacity(0.4), lineWidth: 2)
                )
        case .circle:
            self.background(color)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(Color.white.opacity(0.6), lineWidth: 1.5)
                )
        case .glass:
            self.background(color.opacity(0.7))
                .background(.ultraThinMaterial)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Color.white.opacity(0.4), lineWidth: 1)
                )
        }
    }
}

#Preview {
    ZStack {
        Color.black
        UnlockView(viewModel: ShieldViewModel())
    }
}
