import SwiftUI

/// Unlock UI
struct UnlockView: View {
    @ObservedObject var viewModel: ShieldViewModel

    private let pixelFont = "Silkscreen-Regular"

    var body: some View {
        VStack(spacing: 24) {
            // Lock icon
            Image(systemName: "lock.fill")
                .font(.system(size: 64))
                .foregroundStyle(.white.opacity(0.8))

            // App name
            Text(Constants.appName)
                .font(.custom(pixelFont, size: 24))
                .foregroundStyle(.white)

            // Info message
            Text("Authenticate to unlock")
                .font(.custom(pixelFont, size: 12))
                .foregroundStyle(.white.opacity(0.7))

            if viewModel.showPINInput {
                // PIN input UI
                PINInputView(viewModel: viewModel)
            } else {
                // Touch ID button
                TouchIDButton(viewModel: viewModel)
            }

            // Error message
            if let error = viewModel.authError {
                Text(error)
                    .font(.custom(pixelFont, size: 10))
                    .foregroundStyle(.red)
                    .padding(.top, 8)
            }

            // Mode switch button
            if viewModel.showPINInput && viewModel.isBiometricAvailable && !viewModel.hasTouchIDBeenAttempted {
                // Touch ID not yet attempted - show switch button
                Button(action: {
                    viewModel.switchToTouchID()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "faceid")
                        Text("Use Touch ID")
                            .font(.custom(pixelFont, size: 10))
                    }
                    .foregroundStyle(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            } else if viewModel.showPINInput && viewModel.hasTouchIDBeenAttempted {
                // Touch ID already attempted - show info message
                Text("Touch ID unavailable")
                    .font(.custom(pixelFont, size: 10))
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.top, 8)
            } else if !viewModel.showPINInput && viewModel.isPINSet {
                Button(action: {
                    viewModel.showPINInputIfAvailable()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "number")
                        Text("Use PIN")
                            .font(.custom(pixelFont, size: 10))
                    }
                    .foregroundStyle(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            }
        }
        .padding(40)
    }
}

/// Touch ID button
struct TouchIDButton: View {
    @ObservedObject var viewModel: ShieldViewModel

    private let pixelFont = "Silkscreen-Regular"

    var body: some View {
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
                    Image(systemName: "faceid")
                }
                Text("Unlock")
                    .font(.custom(pixelFont, size: 12))
            }
            .foregroundStyle(.white)
            .frame(width: 160)
            .padding(.vertical, 12)
            .background(Color.blue)
            .overlay(
                Rectangle()
                    .strokeBorder(Color.white.opacity(0.3), lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isAuthenticating)
    }
}

/// PIN input UI
struct PINInputView: View {
    @ObservedObject var viewModel: ShieldViewModel
    @FocusState private var isFocused: Bool

    private let pixelFont = "Silkscreen-Regular"

    var body: some View {
        VStack(spacing: 16) {
            // PIN input field (masked)
            SecureField("Enter PIN", text: $viewModel.pinInput)
                .font(.custom(pixelFont, size: 14))
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

            // PIN confirm button
            Button(action: {
                viewModel.attemptPINUnlock()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Confirm")
                        .font(.custom(pixelFont, size: 12))
                }
                .foregroundStyle(.white)
                .frame(width: 160)
                .padding(.vertical, 12)
                .background(viewModel.pinInput.isEmpty ? Color.gray : Color.green)
                .overlay(
                    Rectangle()
                        .strokeBorder(Color.white.opacity(0.3), lineWidth: 2)
                )
            }
            .buttonStyle(.plain)
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
