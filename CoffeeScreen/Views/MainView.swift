import SwiftUI

/// Main settings view
struct MainView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @StateObject private var pinSettingsViewModel = PINSettingsViewModel()
    @StateObject private var keyCombinationViewModel = KeyCombinationSettingsViewModel()
    @State private var showEscapeKeyPopover = false

    private let pixelFont = "Silkscreen-Regular"

    var body: some View {
        VStack(spacing: 24) {
            // App icon and title
            VStack(spacing: 8) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 64, height: 64)

                Text("Coffee-Screen")
                    .font(.custom(pixelFont, size: 20))
            }

            // PIN settings section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "number")
                        Text("PIN Settings")
                            .font(.custom(pixelFont, size: 14))
                    }

                    Spacer()

                    // Escape key settings button (shown only when PIN is set)
                    if pinSettingsViewModel.isPINSet {
                        Button {
                            showEscapeKeyPopover.toggle()
                        } label: {
                            Image(systemName: "keyboard.badge.ellipsis")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.coffeeBrown.opacity(0.7))
                        }
                        .buttonStyle(.plain)
                        .help("Escape Key Settings")
                        .popover(isPresented: $showEscapeKeyPopover, arrowEdge: .bottom) {
                            EscapeKeyPopoverView(viewModel: keyCombinationViewModel)
                        }
                    }
                }

                if pinSettingsViewModel.isPINSet {
                    // PIN is set - show change/delete options
                    HStack(spacing: 12) {
                        Button("Change") {
                            pinSettingsViewModel.showChangePIN()
                        }
                        .buttonStyle(.pixelSecondary)

                        Button("Delete") {
                            pinSettingsViewModel.deletePIN()
                        }
                        .buttonStyle(.pixelDestructive)
                    }
                    .transition(.asymmetric(
                        insertion: .opacity.animation(.easeIn(duration: 0.15).delay(0.15)),
                        removal: .opacity.animation(.easeOut(duration: 0.15))
                    ))
                } else {
                    // PIN not set
                    PINEntryView(viewModel: pinSettingsViewModel)
                        .transition(.asymmetric(
                            insertion: .opacity.animation(.easeIn(duration: 0.15).delay(0.15)),
                            removal: .opacity.animation(.easeOut(duration: 0.15))
                        ))
                }

                // Success message
                if let success = pinSettingsViewModel.successMessage {
                    Text(success)
                        .font(.custom(pixelFont, size: 10))
                        .foregroundStyle(.green)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: pinSettingsViewModel.isPINSet)
            .padding(16)
            .background(
                Rectangle()
                    .fill(Color.coffeeCream.opacity(0.3))
                    .overlay(
                        Rectangle()
                            .strokeBorder(Color.coffeeBrown.opacity(0.3), lineWidth: 2)
                    )
            )

            // Lock button (shown only when PIN is set)
            if pinSettingsViewModel.isPINSet {
                Button(action: {
                    viewModel.startLock()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                        Text("Lock Screen")
                    }
                }
                .transition(.asymmetric(
                    insertion: .opacity.animation(.easeIn(duration: 0.2).delay(0.2)),
                    removal: .opacity.animation(.easeOut(duration: 0.15))
                ))
                .buttonStyle(PixelButtonStyleLarge(isDisabled: viewModel.appState.isLocked))
                .disabled(viewModel.appState.isLocked)
            }

            Spacer()

            // Power warning
            if !viewModel.appState.isPowerConnected {
                HStack(spacing: 6) {
                    Image(systemName: "bolt.slash.fill")
                    Text("Connect power to prevent sleep")
                        .font(.custom(pixelFont, size: 10))
                }
                .foregroundStyle(.orange)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: pinSettingsViewModel.isPINSet)
        .padding(24)
        .frame(minWidth: 320)
        .fixedSize(horizontal: false, vertical: true)
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
            .environmentObject(MainViewModel())
    }
}

// MARK: - PIN Entry View

struct PINEntryView: View {
    @ObservedObject var viewModel: PINSettingsViewModel
    @State private var isConfirmMode: Bool = false
    @State private var inputText: String = ""
    @State private var showResetButton: Bool = false
    @FocusState private var isFocused: Bool

    private let pixelFont = "Silkscreen-Regular"
    private let maxLength = 8
    private let minLength = 4

    var body: some View {
        VStack(spacing: 16) {
            // Status text
            Text(isConfirmMode ? "Confirm your PIN" : "Enter new PIN (4-8 digits)")
                .font(.custom(pixelFont, size: 10))
                .foregroundStyle(.secondary)

            // PIN dots display
            HStack(spacing: 10) {
                ForEach(0..<maxLength, id: \.self) { index in
                    Rectangle()
                        .fill(index < inputText.count ? Color.coffeeBrown : Color.clear)
                        .frame(width: 14, height: 14)
                        .overlay(
                            Rectangle()
                                .strokeBorder(Color.coffeeBrown.opacity(0.5), lineWidth: 2)
                        )
                }
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .onTapGesture {
                isFocused = true
            }

            // Hidden text field for keyboard input
            TextField("", text: $inputText)
                .focused($isFocused)
                .textFieldStyle(PlainTextFieldStyle())
                .frame(width: 1, height: 1)
                .opacity(0)
                .onChange(of: inputText) { _, newValue in
                    // Allow only numbers + max length limit
                    let filtered = String(newValue.filter { $0.isNumber }.prefix(maxLength))
                    if filtered != newValue {
                        inputText = filtered
                    }

                    // Clear error message on new input
                    if !newValue.isEmpty {
                        viewModel.errorMessage = nil
                    }

                    // Auto-submit when lengths match in confirm mode
                    if isConfirmMode && inputText.count == viewModel.newPIN.count && inputText.count >= minLength {
                        submitPIN()
                    }
                }
                .onSubmit {
                    // Handle enter key
                    if !isConfirmMode && inputText.count >= minLength {
                        goToConfirm()
                    }
                }

            // Error message (fixed height to maintain layout)
            Text(viewModel.errorMessage ?? " ")
                .font(.custom(pixelFont, size: 10))
                .foregroundStyle(viewModel.errorMessage != nil ? .red : .clear)
                .frame(height: 16)

            // Next/Reset buttons (fixed height to maintain layout)
            HStack(spacing: 12) {
                if showResetButton {
                    Button("Reset") {
                        resetToNewPIN()
                    }
                    .buttonStyle(.pixelSecondary)
                } else if !isConfirmMode && inputText.count >= minLength {
                    Button("Next") {
                        goToConfirm()
                    }
                    .buttonStyle(.pixel)
                }
            }
            .frame(height: 46)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 8)
        .onAppear {
            isFocused = true
        }
    }

    private func goToConfirm() {
        viewModel.newPIN = inputText
        isConfirmMode = true
        inputText = ""
        isFocused = true
    }

    private func submitPIN() {
        viewModel.confirmPIN = inputText
        if viewModel.newPIN == viewModel.confirmPIN {
            viewModel.setPIN()
            isConfirmMode = false
            inputText = ""
            showResetButton = false
        } else {
            viewModel.errorMessage = "PINs do not match"
            inputText = ""
            showResetButton = true
            isFocused = true
        }
    }

    private func resetToNewPIN() {
        isConfirmMode = false
        showResetButton = false
        viewModel.newPIN = ""
        viewModel.confirmPIN = ""
        inputText = ""
        viewModel.errorMessage = nil
        isFocused = true
    }
}

// MARK: - Escape Key Popover View

struct EscapeKeyPopoverView: View {
    @ObservedObject var viewModel: KeyCombinationSettingsViewModel

    private let pixelFont = "Silkscreen-Regular"

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title
            HStack(spacing: 8) {
                Image(systemName: "keyboard")
                Text("Escape Key")
                    .font(.custom(pixelFont, size: 14))
            }

            // Info text
            Text("Set a key combination to unlock the screen in emergencies.")
                .font(.custom(pixelFont, size: 10))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Rectangle()
                .fill(Color.coffeeBrown.opacity(0.3))
                .frame(height: 2)

            // Key settings view
            KeyRecorderView(viewModel: viewModel)
        }
        .padding(16)
        .frame(width: 320)
    }
}
