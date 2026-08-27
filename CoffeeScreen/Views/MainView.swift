import SwiftUI

/// Main settings view
struct MainView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @StateObject private var pinSettingsViewModel = PINSettingsViewModel()
    @StateObject private var keyCombinationViewModel = KeyCombinationSettingsViewModel()
    @StateObject private var lockHotkeyViewModel = KeyCombinationSettingsViewModel(
        currentProvider: { LockHotkeyManager.shared.currentHotkey },
        saveAction: { LockHotkeyManager.shared.setHotkey($0) },
        resetAction: { LockHotkeyManager.shared.resetToDefault() }
    )
    @State private var showEscapeKeyPopover = false
    @State private var showLockScreenEditor = false
    @AppStorage("backgroundStyle") private var backgroundStyleRaw: Int = 0

    /// Awake 상태 바인딩 (viewModel과 연결)
    private var awakeBinding: Binding<Bool> {
        Binding(
            get: { viewModel.isStandaloneAwake },
            set: { newValue in
                if newValue {
                    viewModel.startStandaloneAwake()
                } else {
                    viewModel.stopStandaloneAwake()
                }
            }
        )
    }

    private var backgroundStyle: BackgroundStyle {
        get { BackgroundStyle(rawValue: backgroundStyleRaw) ?? .vintageGrid }
        set { backgroundStyleRaw = newValue.rawValue }
    }

    private let pixelFont = "Silkscreen-Regular"
    @State private var isShowingSupportModal: Bool = false

    var body: some View {
        ZStack {
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
                    .foregroundStyle(Color.coffeeDark)
            }

            // PIN settings section
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "number")
                        Text("PIN Settings")
                            .font(.custom(pixelFont, size: 14))
                    }
                    .foregroundStyle(Color.coffeeDark)

                    Spacer()

                    // Action buttons
                    HStack(spacing: 8) {
                        Button {
                            LockScreenEditorWindowController.shared.startEditing()
                        } label: {
                            Image(systemName: "paintpalette.fill")
                        }
                        .buttonStyle(.pixelIcon)
                        .help("Customize Lock Screen")

                        if pinSettingsViewModel.isPINSet {
                            Button {
                                showEscapeKeyPopover.toggle()
                            } label: {
                                Image(systemName: "keyboard.badge.ellipsis")
                            }
                            .buttonStyle(.pixelIcon)
                            .help("Escape Key Settings")
                            .popover(isPresented: $showEscapeKeyPopover, arrowEdge: .bottom) {
                                KeyboardShortcutsPopoverView(
                                    escapeKeyViewModel: keyCombinationViewModel,
                                    lockHotkeyViewModel: lockHotkeyViewModel
                                )
                            }
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

            // Awake Character (시스템 수면 방지)
            AwakeCharacterView(isAwake: awakeBinding)
                .padding(.vertical, 8)

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

            // Buy Me a Coffee support button
            Button {
                isShowingSupportModal = true
            } label: {
                HStack(spacing: 6) {
                    Text("☕")
                    Text("Buy Me a Coffee")
                        .font(.custom(pixelFont, size: 10))
                }
            }
            .buttonStyle(.pixelSecondary)
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

            // Custom Support Modal Overlay (Tap outside to dismiss)
            if isShowingSupportModal {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            isShowingSupportModal = false
                        }
                    }

                SupportCoffeeModalView(isPresented: $isShowingSupportModal)
                    .transition(.scale(scale: 0.95).combined(with: .opacity))
                    .zIndex(10)
            }
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isShowingSupportModal)
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
                .foregroundStyle(Color.coffeeDark.opacity(0.7))

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

// MARK: - Keyboard Shortcuts Popover View

struct KeyboardShortcutsPopoverView: View {
    @ObservedObject var escapeKeyViewModel: KeyCombinationSettingsViewModel
    @ObservedObject var lockHotkeyViewModel: KeyCombinationSettingsViewModel

    @State private var useSameKeyForLock: Bool = LockHotkeyManager.shared.useSameHotkeyForLock
    private let pixelFont = "Silkscreen-Regular"

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // 1. Unlock & Escape Key (해제 단축키)
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "keyboard")
                    Text("Unlock & Escape Key")
                        .font(.custom(pixelFont, size: 14))
                }
                .foregroundStyle(Color.coffeeDark)

                Text("Set a key combination to unlock/escape in emergencies.")
                    .font(.custom(pixelFont, size: 10))
                    .foregroundStyle(Color.coffeeDark.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)

                KeyRecorderView(viewModel: escapeKeyViewModel)
            }

            Rectangle()
                .fill(Color.coffeeBrown.opacity(0.3))
                .frame(height: 1)

            // 2. 잠금 단축키 동일 사용 체크박스
            Toggle(isOn: $useSameKeyForLock) {
                Text("Use same key for Lock Shortcut")
                    .font(.custom(pixelFont, size: 10))
                    .foregroundStyle(Color.coffeeDark)
            }
            .toggleStyle(.checkbox)
            .onChange(of: useSameKeyForLock) { newValue in
                LockHotkeyManager.shared.useSameHotkeyForLock = newValue
            }

            // 3. 독립 잠금 단축키 (체크해제 시만 노출, 체크 시 숨김 및 데이터 제거)
            if !useSameKeyForLock {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                        Text("Independent Lock Shortcut")
                            .font(.custom(pixelFont, size: 14))
                    }
                    .foregroundStyle(Color.coffeeDark)

                    Text("Press this separate combination anywhere to lock the screen.")
                        .font(.custom(pixelFont, size: 10))
                        .foregroundStyle(Color.coffeeDark.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)

                    KeyRecorderView(viewModel: lockHotkeyViewModel)
                }
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "link")
                        .foregroundStyle(Color.coffeeBrown)
                    Text("Lock shortcut is set to same key for 1-key toggle.")
                        .font(.custom(pixelFont, size: 9))
                        .foregroundStyle(Color.coffeeDark.opacity(0.8))
                }
                .padding(8)
                .background(Color.coffeeCream.opacity(0.6))
                .cornerRadius(6)
            }
        }
        .padding(16)
        .frame(width: 340)
        .background(Color.coffeeCream)
        .preferredColorScheme(.light)
        .onAppear {
            useSameKeyForLock = LockHotkeyManager.shared.useSameHotkeyForLock
        }
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

// MARK: - Speech Bubble View

struct SpeechBubbleView: View {
    let text: String
    private let pixelFont = "Silkscreen-Regular"

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // 말풍선 본체
            Text(text)
                .font(.custom(pixelFont, size: 8))
                .foregroundColor(.coffeeBrown)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .strokeBorder(Color.coffeeBrown.opacity(0.5), lineWidth: 1)
                        )
                )

            // 말풍선 꼬리 (삼각형 - 윗선 없이)
            TriangleFill()
                .fill(Color.white)
                .frame(width: 8, height: 6)
                .offset(x: 8, y: 4)

            TriangleTail()
                .stroke(Color.coffeeBrown.opacity(0.5), lineWidth: 1)
                .frame(width: 8, height: 6)
                .offset(x: 8, y: 4)
        }
    }
}

// 말풍선 꼬리 Fill용 (닫힌 삼각형)
struct TriangleFill: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// 말풍선 꼬리 Stroke용 (윗선 없음)
struct TriangleTail: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // 왼쪽 위에서 시작 -> 아래 중앙 -> 오른쪽 위 (윗선 없이)
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        // closeSubpath() 없이 윗선 제거
        return path
    }
}

// MARK: - Awake Character View (마인크래프트 스타일)

struct AwakeCharacterView: View {
    @Binding var isAwake: Bool
    @State private var animationFrame: Int = 0
    @State private var animationTimer: Timer?
    @State private var projectileOffsetX: CGFloat = 0
    @State private var projectileOffsetY: CGFloat = 0
    @State private var projectileVisible: Bool = false
    @State private var throwingTimer: Timer?

    private let pixelSize: CGFloat = 3

    // 마인크래프트 스티브 색상
    private let hairColor = Color(red: 0.35, green: 0.2, blue: 0.1)      // 갈색 머리
    private let skinColor = Color(red: 0.87, green: 0.7, blue: 0.56)     // 피부색
    private let shirtColor = Color(red: 0.2, green: 0.6, blue: 0.2)      // 초록색 셔츠
    private let pantsColor = Color(red: 0.45, green: 0.35, blue: 0.25)   // 갈색 바지
    private let shoeColor = Color(red: 0.3, green: 0.25, blue: 0.2)      // 어두운 갈색 신발
    private let eyeWhite = Color.white
    private let eyeBlue = Color(red: 0.2, green: 0.4, blue: 0.8)
    private let coffeeColor = Color(red: 0.4, green: 0.25, blue: 0.15)
    private let cupColor = Color.white

    // 농민 색상
    private let robeColor = Color(red: 0.45, green: 0.3, blue: 0.2)       // 갈색 로브
    private let robeDarkColor = Color(red: 0.35, green: 0.22, blue: 0.15) // 어두운 갈색
    private let villagerSkin = Color(red: 0.65, green: 0.45, blue: 0.35)  // 주민 피부색 (더 어두운)
    private let villagerNose = Color(red: 0.55, green: 0.38, blue: 0.3)   // 코 색상
    private let eyeGreen = Color(red: 0.2, green: 0.55, blue: 0.25)       // 초록 눈
    private let strawHat = Color(red: 0.85, green: 0.75, blue: 0.4)       // 밀짚모자
    private let strawHatDark = Color(red: 0.65, green: 0.55, blue: 0.3)   // 밀짚모자 어두운

    private let pixelFont = "Silkscreen-Regular"

    var body: some View {
        ZStack(alignment: .topLeading) {
            // 캐릭터 영역
            ZStack {
                // 1. 스티브 & 농민 (기존과 100% 동일한 위치와 중앙 정렬)
                HStack(alignment: .bottom, spacing: 20) {
                    // 스티브 (책상 포함해서 원본 크기)
                    ZStack(alignment: .topTrailing) {
                        Canvas { context, size in
                            if isAwake {
                                drawAwakeSteve(context: context, size: size)
                            } else {
                                drawSleepySteve(context: context, size: size)
                            }
                        }
                        .frame(width: 120, height: 70)

                        // 말풍선 (Awake 상태일 때만)
                        if isAwake {
                            SpeechBubbleView(text: "don't sleep!")
                                .offset(x: -5, y: -8)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }

                    // 농민 (주민 - 원본 크기 & 위치 완벽 고정)
                    Canvas { context, size in
                        if isAwake {
                            if animationFrame == 0 {
                                drawWorkingVillager(context: context, size: size)
                            } else {
                                drawWorkingVillagerFrame2(context: context, size: size)
                            }
                        } else {
                            drawVillager(context: context, size: size)
                        }
                    }
                    .frame(width: 90, height: 70)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, 16)

                // 2. 돌맹이 (던지기 애니메이션 - 스티브 손에서 농민 머리로의 완벽한 원래 궤적)
                if isAwake && projectileVisible {
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 6, height: 6)
                        .offset(x: projectileOffsetX - 60, y: projectileOffsetY - 5)
                }

                // 3. 기여자 캐릭터 (우측 창 끝단 벽에 0px 완벽 밀착)
                HStack {
                    Spacer()
                    Canvas { context, size in
                        if isAwake {
                            if animationFrame == 0 {
                                drawContributorSkyDanceFrame1(context: context, size: size)
                            } else {
                                drawContributorSkyDanceFrame2(context: context, size: size)
                            }
                        } else {
                            drawContributorPeeking(context: context, size: size)
                        }
                    }
                    .frame(width: 50, height: 70)
                }
            }
            .frame(maxWidth: .infinity, alignment: .bottom)
            .padding(.top, 40)

            // 커피잔 토글 버튼 (좌측 상단)
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isAwake.toggle()
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: isAwake ? "cup.and.saucer.fill" : "cup.and.saucer")
                        .font(.system(size: 14))
                    Text(isAwake ? "ON" : "OFF")
                        .font(.custom(pixelFont, size: 10))
                }
                .foregroundColor(isAwake ? Color.coffeeBrown : Color.gray)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isAwake ? Color.coffeeCream : Color.gray.opacity(0.2))
                )
            }
            .buttonStyle(.plain)
            .padding(8)
        }
        .background(
            Rectangle()
                .fill(Color.coffeeCream.opacity(0.3))
                .overlay(
                    Rectangle()
                        .strokeBorder(Color.coffeeBrown.opacity(0.3), lineWidth: 2)
                )
        )
        .onChange(of: isAwake) { _, newValue in
            if newValue {
                startAnimation()
                startThrowing()
            } else {
                stopAnimation()
                stopThrowing()
            }
        }
        .onDisappear {
            stopAnimation()
            stopThrowing()
        }
    }

    // MARK: - Animation Control
    private func startAnimation() {
        animationFrame = 0
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            animationFrame = (animationFrame + 1) % 2
        }
    }

    private func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
        animationFrame = 0
    }

    // MARK: - Throwing Animation Control
    private func startThrowing() {
        throwProjectile()
        throwingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            throwProjectile()
        }
    }

    private func stopThrowing() {
        throwingTimer?.invalidate()
        throwingTimer = nil
        projectileVisible = false
        projectileOffsetX = 0
        projectileOffsetY = 0
    }

    private func throwProjectile() {
        // 초기 위치 (스티브 근처, 위쪽에서 시작)
        projectileOffsetX = 0
        projectileOffsetY = 0
        projectileVisible = true

        // X: 오른쪽으로 이동
        withAnimation(.linear(duration: 0.6)) {
            projectileOffsetX = 120
        }

        // Y: 포물선 (위로 갔다가 아래로)
        withAnimation(.easeIn(duration: 0.6)) {
            projectileOffsetY = 35
        }

        // 도착 후 숨김
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            projectileVisible = false
            projectileOffsetX = 0
            projectileOffsetY = 0
        }
    }

    // MARK: - Awake 스티브 (서서 주민 바라봄, 노트북 닫힘)
    private func drawAwakeSteve(context: GraphicsContext, size: CGSize) {
        let p: CGFloat = 2.5
        let offsetX: CGFloat = 0
        let offsetY = size.height - p * 20 - 2

        // 색상
        let deskColor = Color(red: 0.55, green: 0.35, blue: 0.2)
        let laptopClosed = Color(red: 0.6, green: 0.6, blue: 0.65)

        // === 1. 책상 (상태1과 동일) ===
        let deskTopPixels: [(Int, Int)] = [
            (0, 13), (1, 13), (2, 13), (3, 13), (4, 13), (5, 13), (6, 13), (7, 13), (8, 13), (9, 13), (10, 13),
        ]

        let deskLegPixels: [(Int, Int)] = [
            (1, 14), (1, 15), (1, 16), (1, 17), (1, 18), (1, 19),
            (9, 14), (9, 15), (9, 16), (9, 17), (9, 18), (9, 19),
        ]

        // === 2. 노트북 (닫힌 상태 - 책상 위에 평평하게) ===
        let laptopClosedPixels: [(Int, Int)] = [
            (3, 12), (4, 12), (5, 12), (6, 12), (7, 12), (8, 12),
        ]

        // === 3. 스티브 (서서 오른쪽 바라봄 - 옆모습) ===
        let standingOffsetX: CGFloat = 18

        // 머리 (8x8 정사각형, 오른쪽 바라봄)
        let hairPixels: [(Int, Int)] = [
            // 윗부분 (2줄)
            (0, 0), (1, 0), (2, 0), (3, 0), (4, 0), (5, 0), (6, 0), (7, 0),
            (0, 1), (1, 1), (2, 1), (3, 1), (4, 1), (5, 1), (6, 1), (7, 1),
            // 앞머리 계단 (오른쪽 - 바라보는 방향)
            (7, 2),
            // 뒷머리 계단 형태 (왼쪽)
            (0, 2), (1, 2), (2, 2),
            (0, 3), (1, 3),
            (0, 4),
            (0, 5),
            (0, 6),
            (0, 7),
        ]

        // 얼굴 (오른쪽 바라봄)
        let facePixels: [(Int, Int)] = [
            (3, 2), (4, 2), (5, 2), (6, 2),
            (2, 3), (3, 3), (4, 3), (5, 3), (6, 3), (7, 3),
            (1, 4), (2, 4), (3, 4), (4, 4), (5, 4), (6, 4), (7, 4),
            (1, 5), (2, 5), (3, 5), (4, 5), (5, 5), (6, 5), (7, 5),
            (1, 6), (2, 6), (3, 6), (4, 6), (5, 6), (6, 6), (7, 6),
            (1, 7), (2, 7), (3, 7), (4, 7), (5, 7), (6, 7), (7, 7),
        ]

        // 눈 (오른쪽 바라봄)
        let eyeWhitePixels: [(Int, Int)] = [
            (5, 3), (6, 3),
            (5, 4), (6, 4),
        ]

        let eyeBluePixels: [(Int, Int)] = [
            (6, 3), (6, 4),
        ]

        // 입
        let mouthPixels: [(Int, Int)] = [
            (5, 6), (6, 6),
        ]

        // 몸통 (서있는 자세)
        let bodyPixels: [(Int, Int)] = [
            (1, 8), (2, 8), (3, 8), (4, 8),
            (1, 9), (2, 9), (3, 9), (4, 9),
            (1, 10), (2, 10), (3, 10), (4, 10),
            (1, 11), (2, 11), (3, 11), (4, 11),
            (1, 12), (2, 12), (3, 12), (4, 12),
            (1, 13), (2, 13), (3, 13), (4, 13),
        ]

        // 팔 (자연스럽게 내림)
        let rightArmShirtPixels: [(Int, Int)] = [
            (5, 8), (6, 8),
            (5, 9), (6, 9),
        ]
        let rightHandPixels: [(Int, Int)] = [
            (5, 10), (6, 10),
            (5, 11), (6, 11),
        ]

        // 바지 (서있는 자세)
        let pantsPixels: [(Int, Int)] = [
            (1, 14), (2, 14), (3, 14), (4, 14),
            (1, 15), (2, 15), (3, 15), (4, 15),
            (1, 16), (2, 16), (3, 16), (4, 16),
            (1, 17), (2, 17), (3, 17), (4, 17),
            (1, 18), (2, 18), (3, 18), (4, 18),
        ]

        // 신발
        let shoePixels: [(Int, Int)] = [
            (0, 19), (1, 19), (2, 19), (3, 19), (4, 19), (5, 19),
        ]

        // === 그리기 ===

        // 책상
        drawPixels(context: context, pixels: deskTopPixels, color: deskColor, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: deskLegPixels, color: deskColor, p: p, offsetX: offsetX, offsetY: offsetY)

        // 노트북 (닫힌 상태)
        drawPixels(context: context, pixels: laptopClosedPixels, color: laptopClosed, p: p, offsetX: offsetX, offsetY: offsetY)

        // 스티브 (서있는 자세)
        drawPixels(context: context, pixels: hairPixels, color: hairColor, p: p, offsetX: offsetX + standingOffsetX * p, offsetY: offsetY)
        drawPixels(context: context, pixels: facePixels, color: skinColor, p: p, offsetX: offsetX + standingOffsetX * p, offsetY: offsetY)
        drawPixels(context: context, pixels: eyeWhitePixels, color: eyeWhite, p: p, offsetX: offsetX + standingOffsetX * p, offsetY: offsetY)
        drawPixels(context: context, pixels: eyeBluePixels, color: eyeBlue, p: p, offsetX: offsetX + standingOffsetX * p, offsetY: offsetY)
        drawPixels(context: context, pixels: mouthPixels, color: hairColor.opacity(0.6), p: p, offsetX: offsetX + standingOffsetX * p, offsetY: offsetY)
        drawPixels(context: context, pixels: bodyPixels, color: shirtColor, p: p, offsetX: offsetX + standingOffsetX * p, offsetY: offsetY)
        drawPixels(context: context, pixels: rightArmShirtPixels, color: shirtColor, p: p, offsetX: offsetX + standingOffsetX * p, offsetY: offsetY)
        drawPixels(context: context, pixels: rightHandPixels, color: skinColor, p: p, offsetX: offsetX + standingOffsetX * p, offsetY: offsetY)
        drawPixels(context: context, pixels: pantsPixels, color: pantsColor, p: p, offsetX: offsetX + standingOffsetX * p, offsetY: offsetY)
        drawPixels(context: context, pixels: shoePixels, color: shoeColor, p: p, offsetX: offsetX + standingOffsetX * p, offsetY: offsetY)
    }

    // MARK: - 기본 스티브 (의자에 앉아서 노트북 보는 모습)
    private func drawSleepySteve(context: GraphicsContext, size: CGSize) {
        let p: CGFloat = 2.5
        let offsetX: CGFloat = 0
        let offsetY = size.height - p * 20 - 2

        // 색상
        let deskColor = Color(red: 0.55, green: 0.35, blue: 0.2)
        let laptopSilver = Color(red: 0.75, green: 0.75, blue: 0.78)
        let laptopScreen = Color(red: 0.3, green: 0.5, blue: 0.7)
        let laptopDark = Color(red: 0.5, green: 0.5, blue: 0.55)
        let chairColor = Color(red: 0.5, green: 0.5, blue: 0.52)  // 회색

        // === 1. 책상 (왼쪽) ===
        let deskTopPixels: [(Int, Int)] = [
            (0, 13), (1, 13), (2, 13), (3, 13), (4, 13), (5, 13), (6, 13), (7, 13), (8, 13), (9, 13), (10, 13),
        ]

        let deskLegPixels: [(Int, Int)] = [
            (1, 14), (1, 15), (1, 16), (1, 17), (1, 18), (1, 19),
            (9, 14), (9, 15), (9, 16), (9, 17), (9, 18), (9, 19),
        ]

        // === 2. 노트북 (ㄴ 모양 - 옆에서 본 모습) ===
        // 노트북 화면 (세로 - ㄴ의 세로 부분)
        let laptopScreenBackPixels: [(Int, Int)] = [
            (3, 7), (4, 7),
            (3, 8), (4, 8),
            (3, 9), (4, 9),
            (3, 10), (4, 10),
            (3, 11), (4, 11),
        ]

        // 노트북 화면 안쪽 (스티브가 보는 면)
        let laptopScreenPixels: [(Int, Int)] = [
            (5, 7),
            (5, 8),
            (5, 9),
            (5, 10),
            (5, 11),
        ]

        // 화면 내용 (밝은 점)
        let laptopContentPixels: [(Int, Int)] = [
            (5, 8),
            (5, 9),
        ]

        // 노트북 키보드 (가로 - ㄴ의 가로 부분)
        let laptopBasePixels: [(Int, Int)] = [
            (4, 12), (5, 12), (6, 12), (7, 12), (8, 12), (9, 12),
        ]

        // === 3. 스티브 (의자에 앉은 모습, 옆모습 - 왼쪽 바라봄) ===
        let steveOffsetX: CGFloat = 10

        // 머리 (8x8 정사각형, 옆모습) - 빈틈없이 채움, 몸과 정렬
        // 머리카락 - 계단 형태로 디테일
        let hairPixels: [(Int, Int)] = [
            // 윗부분 (2줄)
            (2, 0), (3, 0), (4, 0), (5, 0), (6, 0), (7, 0), (8, 0), (9, 0),
            (2, 1), (3, 1), (4, 1), (5, 1), (6, 1), (7, 1), (8, 1), (9, 1),
            // 앞머리 계단 (왼쪽)
            (2, 2),
            // 뒷머리 계단 형태 (오른쪽) - 이미지처럼
            (7, 2), (8, 2), (9, 2),
            (8, 3), (9, 3),
            (9, 4),
            (9, 5),
            (9, 6),
            (9, 7),
        ]

        // 얼굴 (옆모습 - 왼쪽 바라봄) - 머리카락 제외한 나머지 전부
        let facePixels: [(Int, Int)] = [
            // y=2 (머리카락 제외)
            (3, 2), (4, 2), (5, 2), (6, 2),
            // y=3 (머리카락 제외)
            (2, 3), (3, 3), (4, 3), (5, 3), (6, 3), (7, 3),
            // y=4 (머리카락 제외)
            (2, 4), (3, 4), (4, 4), (5, 4), (6, 4), (7, 4), (8, 4),
            // y=5 (머리카락 제외)
            (2, 5), (3, 5), (4, 5), (5, 5), (6, 5), (7, 5), (8, 5),
            // y=6 (머리카락 제외)
            (2, 6), (3, 6), (4, 6), (5, 6), (6, 6), (7, 6), (8, 6),
            // y=7 (머리카락 제외)
            (2, 7), (3, 7), (4, 7), (5, 7), (6, 7), (7, 7), (8, 7),
        ]

        // 눈 (옆모습 - 한쪽만, 이미지 참고)
        let eyeWhitePixels: [(Int, Int)] = [
            (3, 3), (4, 3),
            (3, 4), (4, 4),
        ]

        let eyeBluePixels: [(Int, Int)] = [
            (3, 3), (3, 4),
        ]

        // 입 (옆모습)
        let mouthPixels: [(Int, Int)] = [
            (3, 6), (4, 6),
        ]

        // 몸통 (옆모습 - 머리 아래 위치)
        let bodyPixels: [(Int, Int)] = [
            (4, 8), (5, 8), (6, 8), (7, 8),
            (4, 9), (5, 9), (6, 9), (7, 9),
            (4, 10), (5, 10), (6, 10), (7, 10),
            (4, 11), (5, 11), (6, 11), (7, 11),
            (4, 12), (5, 12), (6, 12), (7, 12),
            (4, 13), (5, 13), (6, 13), (7, 13),
        ]

        // 팔 (앞으로 뻗어서 키보드 쪽 - 옆모습)
        let leftArmShirtPixels: [(Int, Int)] = [
            (2, 8), (3, 8),
            (1, 9), (2, 9),
        ]
        let leftHandPixels: [(Int, Int)] = [
            (-1, 10), (0, 10),
            (-1, 11), (0, 11),
        ]
        // 오른팔은 옆모습이라 안 보임
        let rightArmShirtPixels: [(Int, Int)] = []
        let rightHandPixels: [(Int, Int)] = []

        // 바지 - 허벅지 (앉아서 앞으로 뻗음, 옆모습)
        let thighPixels: [(Int, Int)] = [
            (4, 14), (5, 14), (6, 14), (7, 14),
            (2, 15), (3, 15), (4, 15), (5, 15), (6, 15), (7, 15),
        ]

        // 바지 - 종아리 (아래로 내려감)
        let calfPixels: [(Int, Int)] = [
            (2, 16), (3, 16),
            (2, 17), (3, 17),
            (2, 18), (3, 18),
        ]

        // 신발
        let shoePixels: [(Int, Int)] = [
            (1, 19), (2, 19), (3, 19), (4, 19),
        ]

        // 의자 등받이 (옆모습)
        let chairBackPixels: [(Int, Int)] = [
            (8, 8), (9, 8),
            (8, 9), (9, 9),
            (8, 10), (9, 10),
            (8, 11), (9, 11),
            (8, 12), (9, 12),
            (8, 13), (9, 13),
        ]

        // 의자 좌석
        let chairSeatPixels: [(Int, Int)] = [
            (4, 14), (5, 14), (6, 14), (7, 14), (8, 14), (9, 14),
        ]

        // 의자 다리
        let chairLegPixels: [(Int, Int)] = [
            (5, 15), (5, 16), (5, 17), (5, 18), (5, 19),
            (8, 15), (8, 16), (8, 17), (8, 18), (8, 19),
        ]

        // === 그리기 ===

        // 책상
        drawPixels(context: context, pixels: deskTopPixels, color: deskColor, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: deskLegPixels, color: deskColor, p: p, offsetX: offsetX, offsetY: offsetY)

        // 노트북
        drawPixels(context: context, pixels: laptopScreenBackPixels, color: laptopSilver, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: laptopScreenPixels, color: laptopScreen, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: laptopContentPixels, color: Color.white.opacity(0.7), p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: laptopBasePixels, color: laptopDark, p: p, offsetX: offsetX, offsetY: offsetY)

        // 의자 (스티브 뒤에 먼저 그림)
        drawPixels(context: context, pixels: chairBackPixels, color: chairColor, p: p, offsetX: offsetX + steveOffsetX * p, offsetY: offsetY)
        drawPixels(context: context, pixels: chairSeatPixels, color: chairColor, p: p, offsetX: offsetX + steveOffsetX * p, offsetY: offsetY)
        drawPixels(context: context, pixels: chairLegPixels, color: chairColor, p: p, offsetX: offsetX + steveOffsetX * p, offsetY: offsetY)

        // 스티브
        drawPixels(context: context, pixels: hairPixels, color: hairColor, p: p, offsetX: offsetX + steveOffsetX * p, offsetY: offsetY)
        drawPixels(context: context, pixels: facePixels, color: skinColor, p: p, offsetX: offsetX + steveOffsetX * p, offsetY: offsetY)
        drawPixels(context: context, pixels: eyeWhitePixels, color: eyeWhite, p: p, offsetX: offsetX + steveOffsetX * p, offsetY: offsetY)
        drawPixels(context: context, pixels: eyeBluePixels, color: eyeBlue, p: p, offsetX: offsetX + steveOffsetX * p, offsetY: offsetY)
        drawPixels(context: context, pixels: mouthPixels, color: hairColor.opacity(0.6), p: p, offsetX: offsetX + steveOffsetX * p, offsetY: offsetY)
        drawPixels(context: context, pixels: bodyPixels, color: shirtColor, p: p, offsetX: offsetX + steveOffsetX * p, offsetY: offsetY)
        drawPixels(context: context, pixels: leftArmShirtPixels, color: shirtColor, p: p, offsetX: offsetX + steveOffsetX * p, offsetY: offsetY)
        drawPixels(context: context, pixels: leftHandPixels, color: skinColor, p: p, offsetX: offsetX + steveOffsetX * p, offsetY: offsetY)
        drawPixels(context: context, pixels: rightArmShirtPixels, color: shirtColor, p: p, offsetX: offsetX + steveOffsetX * p, offsetY: offsetY)
        drawPixels(context: context, pixels: rightHandPixels, color: skinColor, p: p, offsetX: offsetX + steveOffsetX * p, offsetY: offsetY)
        drawPixels(context: context, pixels: thighPixels, color: pantsColor, p: p, offsetX: offsetX + steveOffsetX * p, offsetY: offsetY)
        drawPixels(context: context, pixels: calfPixels, color: pantsColor, p: p, offsetX: offsetX + steveOffsetX * p, offsetY: offsetY)
        drawPixels(context: context, pixels: shoePixels, color: shoeColor, p: p, offsetX: offsetX + steveOffsetX * p, offsetY: offsetY)
    }

    // MARK: - 서서 자는 농민 (Standing Sleeping Villager)
    private func drawVillager(context: GraphicsContext, size: CGSize) {
        let p: CGFloat = 2.2
        let offsetX = (size.width - p * 16) / 2
        let offsetY = size.height - p * 19 - 2

        let zzzColor = Color(red: 0.3, green: 0.3, blue: 0.5)

        let hatTopPixels: [(Int, Int)] = [
            (5, 0), (6, 0), (7, 0), (8, 0), (9, 0), (10, 0),
            (5, 1), (7, 1), (8, 1), (10, 1),
            (6, 1), (9, 1),
        ]
        let hatTopDarkPixels: [(Int, Int)] = [
            (6, 0), (8, 0),
            (5, 1), (7, 1), (9, 1),
        ]
        let hatBrimPixels: [(Int, Int)] = [
            (2, 2), (3, 2), (4, 2), (5, 2), (6, 2), (7, 2), (8, 2), (9, 2), (10, 2), (11, 2), (12, 2), (13, 2),
        ]
        let hatBrimDarkPixels: [(Int, Int)] = [
            (3, 2), (5, 2), (7, 2), (9, 2), (11, 2),
        ]
        let browPixels: [(Int, Int)] = [
            (4, 3), (5, 3), (6, 3), (7, 3), (8, 3), (9, 3), (10, 3), (11, 3),
        ]
        let facePixels: [(Int, Int)] = [
            (4, 4), (5, 4), (6, 4), (7, 4), (8, 4), (9, 4), (10, 4), (11, 4),
            (4, 5), (5, 5), (6, 5), (7, 5), (8, 5), (9, 5), (10, 5), (11, 5),
            (4, 6), (5, 6), (10, 6), (11, 6),
            (4, 7), (5, 7), (10, 7), (11, 7),
        ]
        let closedEyePixels: [(Int, Int)] = [
            (5, 4), (6, 4), (5, 5), (6, 5),
            (9, 4), (10, 4), (9, 5), (10, 5),
        ]
        let nosePixels: [(Int, Int)] = [
            (6, 5), (7, 5), (8, 5), (9, 5),
            (6, 6), (7, 6), (8, 6), (9, 6),
            (6, 7), (7, 7), (8, 7), (9, 7),
        ]
        let bodyPixels: [(Int, Int)] = [
            (4, 8), (5, 8), (10, 8), (11, 8),
            (4, 9), (5, 9), (10, 9), (11, 9),
            (4, 10), (5, 10), (6, 10), (7, 10), (8, 10), (9, 10), (10, 10), (11, 10),
            (4, 11), (5, 11), (6, 11), (7, 11), (8, 11), (9, 11), (10, 11), (11, 11),
            (4, 12), (5, 12), (6, 12), (7, 12), (8, 12), (9, 12), (10, 12), (11, 12),
            (5, 13), (6, 13), (7, 13), (8, 13), (9, 13), (10, 13),
        ]
        let armPixels: [(Int, Int)] = [
            (2, 8), (3, 8), (2, 9), (3, 9), (2, 10), (3, 10),
            (12, 8), (13, 8), (12, 9), (13, 9), (12, 10), (13, 10),
        ]
        let robeLowerPixels: [(Int, Int)] = [
            (5, 14), (6, 14), (7, 14), (8, 14), (9, 14), (10, 14),
            (5, 15), (6, 15), (7, 15), (8, 15), (9, 15), (10, 15),
            (5, 16), (6, 16), (7, 16), (8, 16), (9, 16), (10, 16),
            (5, 17), (6, 17), (7, 17), (8, 17), (9, 17), (10, 17),
        ]
        let shoePixels: [(Int, Int)] = [
            (4, 18), (5, 18), (6, 18), (9, 18), (10, 18), (11, 18),
        ]
        let zzzPixels: [(Int, Int)] = [
            (13, 1), (14, 1), (15, 1), (14, 2), (13, 3), (14, 3), (15, 3),
            (17, -1), (18, -1), (19, -1), (20, -1), (19, 0), (18, 1), (17, 2), (18, 2), (19, 2), (20, 2),
            (22, -4), (23, -4), (24, -4), (25, -4), (26, -4), (25, -3), (24, -2), (23, -1), (22, 0), (23, 0), (24, 0), (25, 0), (26, 0),
        ]

        drawPixels(context: context, pixels: hatTopPixels, color: strawHat, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: hatTopDarkPixels, color: strawHatDark, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: hatBrimPixels, color: strawHat, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: hatBrimDarkPixels, color: strawHatDark, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: browPixels, color: robeDarkColor, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: facePixels, color: villagerSkin, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: closedEyePixels, color: robeDarkColor, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: nosePixels, color: villagerNose, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: bodyPixels, color: robeColor, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: armPixels, color: robeColor, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: robeLowerPixels, color: robeDarkColor, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: shoePixels, color: shoeColor, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: zzzPixels, color: zzzColor, p: p, offsetX: offsetX, offsetY: offsetY)
    }

    // MARK: - 일하는 농민 (호미질 Frame 1)
    private func drawWorkingVillager(context: GraphicsContext, size: CGSize) {
        let p: CGFloat = 2.2
        let offsetX = (size.width - p * 16) / 2
        let offsetY = size.height - p * 19 - 2

        let hoeHandle = Color(red: 0.5, green: 0.35, blue: 0.2)
        let hoeMetal = Color(red: 0.6, green: 0.6, blue: 0.65)

        let hatTopPixels: [(Int, Int)] = [
            (5, 0), (6, 0), (7, 0), (8, 0), (9, 0), (10, 0),
            (5, 1), (7, 1), (8, 1), (10, 1), (6, 1), (9, 1),
        ]
        let hatTopDarkPixels: [(Int, Int)] = [
            (6, 0), (8, 0), (5, 1), (7, 1), (9, 1),
        ]
        let hatBrimPixels: [(Int, Int)] = [
            (2, 2), (3, 2), (4, 2), (5, 2), (6, 2), (7, 2), (8, 2), (9, 2), (10, 2), (11, 2), (12, 2), (13, 2),
        ]
        let hatBrimDarkPixels: [(Int, Int)] = [
            (3, 2), (5, 2), (7, 2), (9, 2), (11, 2),
        ]
        let browPixels: [(Int, Int)] = [
            (4, 3), (5, 3), (6, 3), (7, 3), (8, 3), (9, 3), (10, 3), (11, 3),
        ]
        let facePixels: [(Int, Int)] = [
            (4, 4), (5, 4), (6, 4), (7, 4), (8, 4), (9, 4), (10, 4), (11, 4),
            (4, 5), (5, 5), (6, 5), (7, 5), (8, 5), (9, 5), (10, 5), (11, 5),
            (4, 6), (5, 6), (10, 6), (11, 6),
            (4, 7), (5, 7), (10, 7), (11, 7),
        ]
        let eyeWhitePixels: [(Int, Int)] = [(5, 4), (6, 4), (9, 4), (10, 4)]
        let eyeGreenPixels: [(Int, Int)] = [(6, 4), (9, 4)]
        let nosePixels: [(Int, Int)] = [
            (6, 5), (7, 5), (8, 5), (9, 5), (6, 6), (7, 6), (8, 6), (9, 6), (6, 7), (7, 7), (8, 7), (9, 7),
        ]
        let bodyPixels: [(Int, Int)] = [
            (4, 8), (5, 8), (6, 8), (7, 8), (8, 8), (9, 8), (10, 8), (11, 8),
            (4, 9), (5, 9), (6, 9), (7, 9), (8, 9), (9, 9), (10, 9), (11, 9),
            (4, 10), (5, 10), (6, 10), (7, 10), (8, 10), (9, 10), (10, 10), (11, 10),
            (4, 11), (5, 11), (6, 11), (7, 11), (8, 11), (9, 11), (10, 11), (11, 11),
            (4, 12), (5, 12), (6, 12), (7, 12), (8, 12), (9, 12), (10, 12), (11, 12),
            (5, 13), (6, 13), (7, 13), (8, 13), (9, 13), (10, 13),
        ]
        let leftArmPixels: [(Int, Int)] = [(2, 7), (3, 7), (1, 6), (2, 6), (0, 5), (1, 5)]
        let rightArmPixels: [(Int, Int)] = [(12, 7), (13, 7), (13, 6), (14, 6), (14, 5), (15, 5)]
        let hoeHandlePixels: [(Int, Int)] = [(0, 4), (1, 4), (0, 3), (1, 3), (0, 2), (1, 2), (0, 1)]
        let hoeMetalPixels: [(Int, Int)] = [(-2, 0), (-1, 0), (0, 0), (1, 0), (2, 0), (-2, 1), (-1, 1)]
        let robeLowerPixels: [(Int, Int)] = [
            (5, 14), (6, 14), (7, 14), (8, 14), (9, 14), (10, 14),
            (5, 15), (6, 15), (7, 15), (8, 15), (9, 15), (10, 15),
            (5, 16), (6, 16), (7, 16), (8, 16), (9, 16), (10, 16),
            (5, 17), (6, 17), (7, 17), (8, 17), (9, 17), (10, 17),
        ]
        let shoePixels: [(Int, Int)] = [(4, 18), (5, 18), (6, 18), (9, 18), (10, 18), (11, 18)]

        drawPixels(context: context, pixels: hoeHandlePixels, color: hoeHandle, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: hoeMetalPixels, color: hoeMetal, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: hatTopPixels, color: strawHat, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: hatTopDarkPixels, color: strawHatDark, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: hatBrimPixels, color: strawHat, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: hatBrimDarkPixels, color: strawHatDark, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: browPixels, color: robeDarkColor, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: facePixels, color: villagerSkin, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: eyeWhitePixels, color: eyeWhite, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: eyeGreenPixels, color: eyeGreen, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: nosePixels, color: villagerNose, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: bodyPixels, color: robeColor, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: leftArmPixels, color: robeColor, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: rightArmPixels, color: robeColor, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: robeLowerPixels, color: robeDarkColor, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: shoePixels, color: shoeColor, p: p, offsetX: offsetX, offsetY: offsetY)
    }

    // MARK: - 일하는 농민 Frame 2 (호미 내려친 자세)
    private func drawWorkingVillagerFrame2(context: GraphicsContext, size: CGSize) {
        let p: CGFloat = 2.2
        let offsetX = (size.width - p * 16) / 2
        let offsetY = size.height - p * 19 - 2

        let hoeHandle = Color(red: 0.5, green: 0.35, blue: 0.2)
        let hoeMetal = Color(red: 0.6, green: 0.6, blue: 0.65)

        let hatTopPixels: [(Int, Int)] = [
            (5, 0), (6, 0), (7, 0), (8, 0), (9, 0), (10, 0),
            (5, 1), (7, 1), (8, 1), (10, 1), (6, 1), (9, 1),
        ]
        let hatTopDarkPixels: [(Int, Int)] = [
            (6, 0), (8, 0), (5, 1), (7, 1), (9, 1),
        ]
        let hatBrimPixels: [(Int, Int)] = [
            (2, 2), (3, 2), (4, 2), (5, 2), (6, 2), (7, 2), (8, 2), (9, 2), (10, 2), (11, 2), (12, 2), (13, 2),
        ]
        let hatBrimDarkPixels: [(Int, Int)] = [
            (3, 2), (5, 2), (7, 2), (9, 2), (11, 2),
        ]
        let browPixels: [(Int, Int)] = [
            (4, 3), (5, 3), (6, 3), (7, 3), (8, 3), (9, 3), (10, 3), (11, 3),
        ]
        let facePixels: [(Int, Int)] = [
            (4, 4), (5, 4), (6, 4), (7, 4), (8, 4), (9, 4), (10, 4), (11, 4),
            (4, 5), (5, 5), (6, 5), (7, 5), (8, 5), (9, 5), (10, 5), (11, 5),
            (4, 6), (5, 6), (10, 6), (11, 6),
            (4, 7), (5, 7), (10, 7), (11, 7),
        ]
        let eyeWhitePixels: [(Int, Int)] = [(5, 4), (6, 4), (9, 4), (10, 4)]
        let eyeGreenPixels: [(Int, Int)] = [(6, 4), (9, 4)]
        let nosePixels: [(Int, Int)] = [
            (6, 5), (7, 5), (8, 5), (9, 5), (6, 6), (7, 6), (8, 6), (9, 6), (6, 7), (7, 7), (8, 7), (9, 7),
        ]
        let bodyPixels: [(Int, Int)] = [
            (4, 8), (5, 8), (6, 8), (7, 8), (8, 8), (9, 8), (10, 8), (11, 8),
            (4, 9), (5, 9), (6, 9), (7, 9), (8, 9), (9, 9), (10, 9), (11, 9),
            (4, 10), (5, 10), (6, 10), (7, 10), (8, 10), (9, 10), (10, 10), (11, 10),
            (4, 11), (5, 11), (6, 11), (7, 11), (8, 11), (9, 11), (10, 11), (11, 11),
            (4, 12), (5, 12), (6, 12), (7, 12), (8, 12), (9, 12), (10, 12), (11, 12),
            (5, 13), (6, 13), (7, 13), (8, 13), (9, 13), (10, 13),
        ]
        let leftArmPixels: [(Int, Int)] = [(2, 8), (3, 8), (1, 9), (2, 9), (0, 10), (1, 10)]
        let rightArmPixels: [(Int, Int)] = [(12, 8), (13, 8), (13, 9), (14, 9), (14, 10), (15, 10)]
        let hoeHandlePixels: [(Int, Int)] = [(-1, 10), (0, 10), (-2, 11), (-1, 11), (-3, 12), (-2, 12), (-4, 13), (-3, 13)]
        let hoeMetalPixels: [(Int, Int)] = [(-6, 13), (-5, 13), (-4, 13), (-6, 14), (-5, 14), (-6, 15)]
        let robeLowerPixels: [(Int, Int)] = [
            (5, 14), (6, 14), (7, 14), (8, 14), (9, 14), (10, 14),
            (5, 15), (6, 15), (7, 15), (8, 15), (9, 15), (10, 15),
            (5, 16), (6, 16), (7, 16), (8, 16), (9, 16), (10, 16),
            (5, 17), (6, 17), (7, 17), (8, 17), (9, 17), (10, 17),
        ]
        let shoePixels: [(Int, Int)] = [(4, 18), (5, 18), (6, 18), (9, 18), (10, 18), (11, 18)]

        drawPixels(context: context, pixels: hoeHandlePixels, color: hoeHandle, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: hoeMetalPixels, color: hoeMetal, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: hatTopPixels, color: strawHat, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: hatTopDarkPixels, color: strawHatDark, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: hatBrimPixels, color: strawHat, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: hatBrimDarkPixels, color: strawHatDark, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: browPixels, color: robeDarkColor, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: facePixels, color: villagerSkin, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: eyeWhitePixels, color: eyeWhite, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: eyeGreenPixels, color: eyeGreen, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: nosePixels, color: villagerNose, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: bodyPixels, color: robeColor, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: leftArmPixels, color: robeColor, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: rightArmPixels, color: robeColor, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: robeLowerPixels, color: robeDarkColor, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: shoePixels, color: shoeColor, p: p, offsetX: offsetX, offsetY: offsetY)
    }

    // MARK: - 기여자 (준혁님) OFF 상태: 오른쪽 창 테두리 뒤에서 45도 고개 내밀고 빼꼼 쳐다보기 (양쪽 눈 & 미니 안경) 👀
    private func drawContributorPeeking(context: GraphicsContext, size: CGSize) {
        let p: CGFloat = 2.0 // 춤추는 캐릭터와 100% 동일한 픽셀 크기
        // 오른쪽 벽(size.width)에 24픽셀 너비가 정확히 밀착되도록 오프셋 설정
        let offsetX = size.width - p * 24
        let offsetY = size.height - p * 22 - 2

        let cHair = Color(red: 0.15, green: 0.15, blue: 0.18)
        let cSkin = Color(red: 1.0, green: 0.86, blue: 0.76)
        let cGlasses = Color(red: 0.65, green: 0.65, blue: 0.70)
        let cEyes = Color(red: 0.1, green: 0.1, blue: 0.12)
        let cShirt = Color(red: 0.11, green: 0.12, blue: 0.14)

        // 1. 45도 기울어진 바가지 댄디 헤어
        var hairPixels: [(Int, Int)] = []
        for x in 15...21 {
            hairPixels.append((x, 8))
            hairPixels.append((x, 9))
        }
        for x in 13...22 { hairPixels.append((x, 10)) }
        for x in 12...22 { hairPixels.append((x, 11)) }
        hairPixels.append(contentsOf: [
            (11, 12), (12, 12), (14, 12), (15, 12),
            (17, 12), (18, 12), (20, 12), (21, 12)
        ])

        // 2. 얼굴 (45도 틸트 피부)
        var facePixels: [(Int, Int)] = []
        for y in 12...17 {
            for x in 12...22 {
                if !(y == 12 && [11, 12, 14, 15, 17, 18, 20, 21].contains(x)) {
                    facePixels.append((x, y))
                }
            }
        }

        // 3. 둥근 안경 & 양쪽 눈 👀 (왼쪽 눈 + 오른쪽 눈 모두 선명)
        let glassesPixels: [(Int, Int)] = [
            (13, 14), (14, 14), (15, 14),
            (13, 15), (15, 15),
            (13, 16), (14, 16), (15, 16),
            (16, 14), // 안경 브릿지
            (17, 14), (18, 14), (19, 14),
            (17, 15), (19, 15),
            (17, 16), (18, 16), (19, 16)
        ]
        let eyesPixels: [(Int, Int)] = [
            (14, 15), // 좌측 눈동자
            (18, 15)  // 우측 눈동자
        ]

        // 4. 벽 잡고 있는 귀여운 손 🖐️
        let handPixels: [(Int, Int)] = [
            (10, 18), (11, 18), (10, 19), (11, 19), (12, 19)
        ]

        // 5. 벽 뒤로 가려진 블랙 폴로 상의 어깨
        var shirtPixels: [(Int, Int)] = []
        for y in 18...22 {
            for x in 13...23 {
                shirtPixels.append((x, y))
            }
        }

        drawPixels(context: context, pixels: hairPixels, color: cHair, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: facePixels, color: cSkin, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: glassesPixels, color: cGlasses, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: eyesPixels, color: cEyes, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: handPixels, color: cSkin, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: shirtPixels, color: cShirt, p: p, offsetX: offsetX, offsetY: offsetY)
    }

    // MARK: - 기여자 (준혁님) ON 상태 춤: 하늘 찌르기 디스코 Frame 1 ☝️🕺
    private func drawContributorSkyDanceFrame1(context: GraphicsContext, size: CGSize) {
        let p: CGFloat = 2.0
        let offsetX = (size.width - p * 16) / 2
        let offsetY = size.height - p * 20 - 2

        let cHair = Color(red: 0.15, green: 0.15, blue: 0.18)
        let cSkin = Color(red: 1.0, green: 0.86, blue: 0.76)
        let cGlasses = Color(red: 0.65, green: 0.65, blue: 0.70)
        let cEyes = Color(red: 0.1, green: 0.1, blue: 0.12)
        let cMouth = Color(red: 0.85, green: 0.45, blue: 0.45)
        let cShirt = Color(red: 0.11, green: 0.12, blue: 0.14)
        let cLogo = Color(red: 0.92, green: 0.15, blue: 0.22)
        let cPants = Color(red: 0.16, green: 0.19, blue: 0.24)
        let cShoes = Color(red: 0.96, green: 0.96, blue: 0.98)
        let cNote = Color(red: 1.0, green: 0.75, blue: 0.2) // 골드 음표

        var hairPixels: [(Int, Int)] = []
        for x in 4...11 {
            hairPixels.append((x, 0))
            hairPixels.append((x, 1))
            hairPixels.append((x, 2))
        }
        hairPixels.append(contentsOf: [(3, 1), (12, 1), (4, 3), (5, 3), (7, 3), (8, 3), (10, 3), (11, 3)])

        var facePixels: [(Int, Int)] = []
        for x in 4...11 {
            for y in 3...7 {
                if !((x == 4 || x == 5 || x == 7 || x == 8 || x == 10 || x == 11) && y == 3) {
                    facePixels.append((x, y))
                }
            }
        }

        let glassesPixels: [(Int, Int)] = [
            (5, 4), (6, 4), (7, 4), (8, 4), (9, 4),
            (5, 5), (6, 5), (8, 5), (9, 5)
        ]
        let winkEyesPixels: [(Int, Int)] = [(5, 5), (6, 5), (9, 5)]
        let mouthPixels: [(Int, Int)] = [(7, 7), (8, 7)]

        var shirtPixels: [(Int, Int)] = []
        for x in 2...11 {
            for y in 8...13 {
                shirtPixels.append((x, y))
            }
        }
        let logoPixels: [(Int, Int)] = [(5, 10)]

        // 우측 팔: 하늘을 찌르는 디스코 손가락 ☝️
        let rightArmPixels: [(Int, Int)] = [(12, 8), (13, 7), (13, 6), (14, 5), (14, 4)]
        let rightPointingHand: [(Int, Int)] = [(14, 3), (14, 2), (14, 1)] // ☝️

        // 좌측 팔: 엉덩이에 손
        let leftArmPixels: [(Int, Int)] = [(1, 8), (0, 9), (0, 10)]
        let leftHandPixels: [(Int, Int)] = [(0, 11)]

        var pantsPixels: [(Int, Int)] = []
        for y in 14...17 {
            pantsPixels.append(contentsOf: [(2, y), (3, y), (4, y), (8, y), (9, y), (10, y)])
        }
        let shoePixels: [(Int, Int)] = [
            (1, 18), (2, 18), (3, 18), (4, 18),
            (8, 18), (9, 18), (10, 18), (11, 18)
        ]
        let musicNotePixels: [(Int, Int)] = [(16, -2), (17, -2), (17, -1), (16, 0)]

        drawPixels(context: context, pixels: hairPixels, color: cHair, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: facePixels, color: cSkin, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: glassesPixels, color: cGlasses, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: winkEyesPixels, color: cEyes, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: mouthPixels, color: cMouth, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: shirtPixels, color: cShirt, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: logoPixels, color: cLogo, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: rightArmPixels, color: cShirt, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: rightPointingHand, color: cSkin, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: leftArmPixels, color: cShirt, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: leftHandPixels, color: cSkin, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: pantsPixels, color: cPants, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: shoePixels, color: cShoes, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: musicNotePixels, color: cNote, p: p, offsetX: offsetX, offsetY: offsetY)
    }

    // MARK: - 기여자 (준혁님) ON 상태 춤: 하늘 찌르기 디스코 Frame 2 ☝️🕺
    private func drawContributorSkyDanceFrame2(context: GraphicsContext, size: CGSize) {
        let p: CGFloat = 2.0
        let offsetX = (size.width - p * 16) / 2
        let offsetY = size.height - p * 20 - 2

        let cHair = Color(red: 0.15, green: 0.15, blue: 0.18)
        let cSkin = Color(red: 1.0, green: 0.86, blue: 0.76)
        let cGlasses = Color(red: 0.65, green: 0.65, blue: 0.70)
        let cEyes = Color(red: 0.1, green: 0.1, blue: 0.12)
        let cMouth = Color(red: 0.85, green: 0.45, blue: 0.45)
        let cShirt = Color(red: 0.11, green: 0.12, blue: 0.14)
        let cLogo = Color(red: 0.92, green: 0.15, blue: 0.22)
        let cPants = Color(red: 0.16, green: 0.19, blue: 0.24)
        let cShoes = Color(red: 0.96, green: 0.96, blue: 0.98)
        let cNote = Color(red: 1.0, green: 0.75, blue: 0.2)

        var hairPixels: [(Int, Int)] = []
        for x in 4...11 {
            hairPixels.append((x, 0))
            hairPixels.append((x, 1))
            hairPixels.append((x, 2))
        }
        hairPixels.append(contentsOf: [(3, 1), (12, 1), (4, 3), (5, 3), (7, 3), (8, 3), (10, 3), (11, 3)])

        var facePixels: [(Int, Int)] = []
        for x in 4...11 {
            for y in 3...7 {
                if !((x == 4 || x == 5 || x == 7 || x == 8 || x == 10 || x == 11) && y == 3) {
                    facePixels.append((x, y))
                }
            }
        }

        let glassesPixels: [(Int, Int)] = [
            (5, 4), (6, 4), (7, 4), (8, 4), (9, 4),
            (5, 5), (6, 5), (8, 5), (9, 5)
        ]
        let winkEyesPixels: [(Int, Int)] = [(6, 5), (8, 5), (9, 5)]
        let mouthPixels: [(Int, Int)] = [(7, 7), (8, 7)]

        var shirtPixels: [(Int, Int)] = []
        for x in 4...13 {
            for y in 8...13 {
                shirtPixels.append((x, y))
            }
        }
        let logoPixels: [(Int, Int)] = [(7, 10)]

        // 좌측 팔: 하늘을 찌르는 디스코 손가락 ☝️
        let leftArmPixels: [(Int, Int)] = [(3, 8), (2, 7), (2, 6), (1, 5), (1, 4)]
        let leftPointingHand: [(Int, Int)] = [(1, 3), (1, 2), (1, 1)] // ☝️

        // 우측 팔: 엉덩이에 손
        let rightArmPixels: [(Int, Int)] = [(14, 8), (15, 9), (15, 10)]
        let rightHandPixels: [(Int, Int)] = [(15, 11)]

        var pantsPixels: [(Int, Int)] = []
        for y in 14...17 {
            pantsPixels.append(contentsOf: [(5, y), (6, y), (7, y), (11, y), (12, y), (13, y)])
        }
        let shoePixels: [(Int, Int)] = [
            (4, 18), (5, 18), (6, 18), (7, 18),
            (11, 18), (12, 18), (13, 18), (14, 18)
        ]
        let musicNotePixels: [(Int, Int)] = [(-1, -2), (0, -2), (0, -1), (-1, 0)]

        drawPixels(context: context, pixels: hairPixels, color: cHair, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: facePixels, color: cSkin, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: glassesPixels, color: cGlasses, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: winkEyesPixels, color: cEyes, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: mouthPixels, color: cMouth, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: shirtPixels, color: cShirt, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: logoPixels, color: cLogo, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: leftArmPixels, color: cShirt, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: leftPointingHand, color: cSkin, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: rightArmPixels, color: cShirt, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: rightHandPixels, color: cSkin, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: pantsPixels, color: cPants, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: shoePixels, color: cShoes, p: p, offsetX: offsetX, offsetY: offsetY)
        drawPixels(context: context, pixels: musicNotePixels, color: cNote, p: p, offsetX: offsetX, offsetY: offsetY)
    }

    private func drawPixels(context: GraphicsContext, pixels: [(Int, Int)], color: Color, p: CGFloat, offsetX: CGFloat, offsetY: CGFloat) {
        for (px, py) in pixels {
            let rect = CGRect(x: offsetX + CGFloat(px) * p, y: offsetY + CGFloat(py) * p, width: p, height: p)
            context.fill(Path(rect), with: .color(color))
        }
    }
}
