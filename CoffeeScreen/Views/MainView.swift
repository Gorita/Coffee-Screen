import SwiftUI

/// Main settings view
struct MainView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @StateObject private var pinSettingsViewModel = PINSettingsViewModel()
    @StateObject private var keyCombinationViewModel = KeyCombinationSettingsViewModel()
    @State private var showEscapeKeyPopover = false
    @AppStorage("backgroundStyle") private var backgroundStyleRaw: Int = 0

    private var backgroundStyle: BackgroundStyle {
        get { BackgroundStyle(rawValue: backgroundStyleRaw) ?? .vintageGrid }
        set { backgroundStyleRaw = newValue.rawValue }
    }

    private let pixelFont = "Silkscreen-Regular"

    var body: some View {
        VStack(spacing: 24) {
            // App icon and title (clickable to toggle background)
            VStack(spacing: 8) {
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        backgroundStyleRaw = backgroundStyleRaw == 0 ? 1 : 0
                    }
                } label: {
                    Image(nsImage: NSApp.applicationIconImage)
                        .resizable()
                        .frame(width: 64, height: 64)
                }
                .buttonStyle(.plain)
                .help("Click to change background")

                Text("Coffee-Screen")
                    .font(.custom(pixelFont, size: 20))
            }

            // PIN settings section
            VStack(alignment: .leading, spacing: 16) {
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
                        }
                        .buttonStyle(.pixelIcon)
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
        .frame(minWidth: 320, maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Group {
                if backgroundStyle == .vintageGrid {
                    VintageGridBackground()
                } else {
                    PixelArtBackground()
                }
            }
            .ignoresSafeArea()
        )
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

// MARK: - Background Style Enum

enum BackgroundStyle: Int {
    case vintageGrid = 0
    case pixelArt = 1

    mutating func toggle() {
        self = self == .vintageGrid ? .pixelArt : .vintageGrid
    }
}

// MARK: - Vintage Grid Background

struct VintageGridBackground: View {
    private let gridSpacing: CGFloat = 20
    private let lineWidth: CGFloat = 0.5

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background color (vintage paper)
                Color(red: 0.94, green: 0.91, blue: 0.84)

                // Grid pattern
                Canvas { context, size in
                    let gridColor = Color(red: 0.75, green: 0.70, blue: 0.60).opacity(0.5)

                    // Vertical lines
                    var x: CGFloat = 0
                    while x <= size.width {
                        var path = Path()
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: size.height))
                        context.stroke(path, with: .color(gridColor), lineWidth: lineWidth)
                        x += gridSpacing
                    }

                    // Horizontal lines
                    var y: CGFloat = 0
                    while y <= size.height {
                        var path = Path()
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: size.width, y: y))
                        context.stroke(path, with: .color(gridColor), lineWidth: lineWidth)
                        y += gridSpacing
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)

                // Vignette overlay (darker edges)
                let maxDimension = max(geometry.size.width, geometry.size.height)
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        Color(red: 0.35, green: 0.25, blue: 0.15).opacity(0.6)
                    ]),
                    center: .center,
                    startRadius: maxDimension * 0.05,
                    endRadius: maxDimension * 0.6
                )
            }
        }
    }
}

// MARK: - Pixel Art Pattern Background

struct PixelArtBackground: View {
    private let tileSize: CGFloat = 36
    private let iconColor = Color(red: 0.88, green: 0.84, blue: 0.78)
    private let bgColor = Color(red: 0.96, green: 0.94, blue: 0.90)

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background color (warm cream)
                bgColor

                // Pixel art icons pattern
                Canvas { context, size in
                    let cols = Int(ceil(size.width / tileSize)) + 1
                    let rows = Int(ceil(size.height / tileSize)) + 1

                    for row in 0..<rows {
                        for col in 0..<cols {
                            let x = CGFloat(col) * tileSize + (row.isMultiple(of: 2) ? tileSize / 2 : 0)
                            let y = CGFloat(row) * tileSize

                            // Cycle through different icons
                            let iconType = (row * 3 + col) % 4
                            switch iconType {
                            case 0:
                                drawCoffeeCup(context: context, at: CGPoint(x: x + 6, y: y + 6))
                            case 1:
                                drawLock(context: context, at: CGPoint(x: x + 6, y: y + 6))
                            case 2:
                                drawCoffeeBean(context: context, at: CGPoint(x: x + 8, y: y + 8))
                            case 3:
                                drawHeart(context: context, at: CGPoint(x: x + 8, y: y + 8))
                            default:
                                break
                            }
                        }
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
    }

    // Cute pixel coffee cup
    private func drawCoffeeCup(context: GraphicsContext, at point: CGPoint) {
        var path = Path()
        // Cup body (rounded)
        path.addRect(CGRect(x: point.x + 1, y: point.y + 6, width: 10, height: 8))
        path.addRect(CGRect(x: point.x + 2, y: point.y + 5, width: 8, height: 1))
        path.addRect(CGRect(x: point.x + 2, y: point.y + 14, width: 8, height: 1))
        // Handle
        path.addRect(CGRect(x: point.x + 11, y: point.y + 7, width: 3, height: 2))
        path.addRect(CGRect(x: point.x + 13, y: point.y + 8, width: 1, height: 3))
        path.addRect(CGRect(x: point.x + 11, y: point.y + 11, width: 3, height: 2))
        context.fill(path, with: .color(iconColor.opacity(0.35)))

        // Steam
        var steam = Path()
        steam.addRect(CGRect(x: point.x + 3, y: point.y + 1, width: 2, height: 2))
        steam.addRect(CGRect(x: point.x + 6, y: point.y + 0, width: 2, height: 3))
        steam.addRect(CGRect(x: point.x + 9, y: point.y + 2, width: 2, height: 2))
        context.fill(steam, with: .color(iconColor.opacity(0.2)))
    }

    // Cute pixel lock
    private func drawLock(context: GraphicsContext, at point: CGPoint) {
        var path = Path()
        // Body (rounded rectangle feel)
        path.addRect(CGRect(x: point.x + 2, y: point.y + 7, width: 10, height: 8))
        path.addRect(CGRect(x: point.x + 3, y: point.y + 6, width: 8, height: 1))
        path.addRect(CGRect(x: point.x + 3, y: point.y + 15, width: 8, height: 1))
        // Shackle
        path.addRect(CGRect(x: point.x + 4, y: point.y + 2, width: 2, height: 6))
        path.addRect(CGRect(x: point.x + 8, y: point.y + 2, width: 2, height: 6))
        path.addRect(CGRect(x: point.x + 4, y: point.y + 1, width: 6, height: 2))
        context.fill(path, with: .color(iconColor.opacity(0.35)))

        // Keyhole
        var keyhole = Path()
        keyhole.addRect(CGRect(x: point.x + 6, y: point.y + 9, width: 2, height: 2))
        keyhole.addRect(CGRect(x: point.x + 6.5, y: point.y + 11, width: 1, height: 2))
        context.fill(keyhole, with: .color(bgColor))
    }

    // Cute pixel coffee bean
    private func drawCoffeeBean(context: GraphicsContext, at point: CGPoint) {
        var path = Path()
        // Bean shape (oval-ish)
        path.addRect(CGRect(x: point.x + 2, y: point.y + 1, width: 8, height: 2))
        path.addRect(CGRect(x: point.x + 1, y: point.y + 3, width: 10, height: 8))
        path.addRect(CGRect(x: point.x + 2, y: point.y + 11, width: 8, height: 2))
        context.fill(path, with: .color(iconColor.opacity(0.35)))

        // Center line
        var line = Path()
        line.addRect(CGRect(x: point.x + 5, y: point.y + 3, width: 2, height: 8))
        context.fill(line, with: .color(bgColor.opacity(0.8)))
    }

    // Cute pixel heart
    private func drawHeart(context: GraphicsContext, at point: CGPoint) {
        var path = Path()
        // Heart shape
        path.addRect(CGRect(x: point.x + 1, y: point.y + 2, width: 4, height: 4))
        path.addRect(CGRect(x: point.x + 7, y: point.y + 2, width: 4, height: 4))
        path.addRect(CGRect(x: point.x + 0, y: point.y + 4, width: 12, height: 4))
        path.addRect(CGRect(x: point.x + 1, y: point.y + 8, width: 10, height: 2))
        path.addRect(CGRect(x: point.x + 2, y: point.y + 10, width: 8, height: 2))
        path.addRect(CGRect(x: point.x + 3, y: point.y + 12, width: 6, height: 1))
        path.addRect(CGRect(x: point.x + 4, y: point.y + 13, width: 4, height: 1))
        path.addRect(CGRect(x: point.x + 5, y: point.y + 14, width: 2, height: 1))
        context.fill(path, with: .color(iconColor.opacity(0.35)))
    }
}
