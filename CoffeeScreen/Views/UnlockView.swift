import SwiftUI

/// 잠금 해제 UI
struct UnlockView: View {
    @ObservedObject var viewModel: ShieldViewModel

    var body: some View {
        VStack(spacing: 24) {
            // 잠금 아이콘
            Image(systemName: "lock.fill")
                .font(.system(size: 64))
                .foregroundStyle(.white.opacity(0.8))

            // 앱 이름
            Text(Constants.appName)
                .font(.title)
                .fontWeight(.medium)
                .foregroundStyle(.white)

            // 안내 메시지
            Text(Constants.Strings.unlockReason)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))

            if viewModel.showPINInput {
                // PIN 입력 UI
                PINInputView(viewModel: viewModel)
            } else {
                // Touch ID 버튼
                TouchIDButton(viewModel: viewModel)
            }

            // 에러 메시지
            if let error = viewModel.authError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.top, 8)
            }

            // 모드 전환 버튼
            if viewModel.showPINInput && viewModel.isBiometricAvailable && !viewModel.hasTouchIDBeenAttempted {
                // Touch ID 아직 시도 안 함 - 전환 버튼 표시
                Button(action: {
                    viewModel.switchToTouchID()
                }) {
                    Label(String(localized: "auth.useTouchID"), systemImage: "faceid")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            } else if viewModel.showPINInput && viewModel.hasTouchIDBeenAttempted {
                // Touch ID 이미 시도함 - 안내 메시지 표시
                Text(String(localized: "auth.touchIDUnavailable"))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.top, 8)
            } else if !viewModel.showPINInput && viewModel.isPINSet {
                Button(action: {
                    viewModel.showPINInputIfAvailable()
                }) {
                    Label(String(localized: "auth.usePIN"), systemImage: "number")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            }
        }
        .padding(40)
    }
}

/// Touch ID 버튼
struct TouchIDButton: View {
    @ObservedObject var viewModel: ShieldViewModel

    var body: some View {
        Button(action: {
            viewModel.attemptTouchID()
        }) {
            HStack {
                if viewModel.isAuthenticating {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.8)
                        .tint(.white)
                } else {
                    Image(systemName: "faceid")
                }
                Text(Constants.Strings.unlockButton)
            }
            .frame(width: 160)
            .padding(.vertical, 12)
        }
        .buttonStyle(.borderedProminent)
        .tint(.blue)
        .disabled(viewModel.isAuthenticating)
    }
}

/// PIN 입력 UI
struct PINInputView: View {
    @ObservedObject var viewModel: ShieldViewModel
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 16) {
            // PIN 입력 필드 (마스킹)
            SecureField(String(localized: "pin.placeholder"), text: $viewModel.pinInput)
                .textFieldStyle(.roundedBorder)
                .frame(width: 200)
                .multilineTextAlignment(.center)
                .focused($isFocused)
                .onSubmit {
                    viewModel.attemptPINUnlock()
                }
                .onAppear {
                    isFocused = true
                }

            // PIN 확인 버튼
            Button(action: {
                viewModel.attemptPINUnlock()
            }) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text(String(localized: "pin.confirm"))
                }
                .frame(width: 160)
                .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .disabled(viewModel.pinInput.isEmpty)
        }
    }
}

#Preview {
    ZStack {
        Color.black
        UnlockView(viewModel: ShieldViewModel())
    }
}
