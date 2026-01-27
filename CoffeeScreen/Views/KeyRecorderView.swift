import SwiftUI
import AppKit

/// Emergency escape key settings view
struct KeyRecorderView: View {
    @ObservedObject var viewModel: KeyCombinationSettingsViewModel

    private let pixelFont = "Silkscreen-Regular"

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if viewModel.isRecording {
                recordingView
            } else {
                displayView
            }

            // Message display
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.custom(pixelFont, size: 10))
                    .foregroundStyle(.red)
            }

            if let success = viewModel.successMessage {
                Text(success)
                    .font(.custom(pixelFont, size: 10))
                    .foregroundStyle(.green)
            }
        }
    }

    // MARK: - Display View

    private var displayView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Current Key")
                    .font(.custom(pixelFont, size: 10))
                    .foregroundStyle(.secondary)

                Text(viewModel.currentKeyDisplay)
                    .font(.custom(pixelFont, size: 12))
                    .foregroundStyle(Color.coffeeDark)
            }

            Spacer()

            HStack(spacing: 8) {
                Button("Change") {
                    viewModel.startRecording()
                }
                .buttonStyle(.pixel)
                .fixedSize()

                Button("Reset") {
                    viewModel.resetToDefault()
                }
                .buttonStyle(.pixelSecondary)
                .fixedSize()
            }
        }
    }

    // MARK: - Recording View

    private var recordingView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Press new key combination")
                .font(.custom(pixelFont, size: 10))
                .foregroundStyle(.secondary)

            // Key capture area
            KeyCaptureView(viewModel: viewModel)
                .frame(height: 44)
                .background(
                    Rectangle()
                        .fill(Color.coffeeCream)
                        .overlay(
                            Rectangle()
                                .strokeBorder(Color.coffeeBrown, lineWidth: 2)
                        )
                )

            // Recorded key display
            if !viewModel.recordedKeyDisplay.isEmpty {
                HStack {
                    Text(viewModel.recordedKeyDisplay)
                        .font(.custom(pixelFont, size: 14))
                        .foregroundStyle(Color.coffeeDark)

                    if viewModel.bothShiftsPressed {
                        Text("(Both Shifts)")
                            .font(.custom(pixelFont, size: 10))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Buttons
            HStack(spacing: 8) {
                Button("Cancel") {
                    viewModel.cancelRecording()
                }
                .buttonStyle(.pixelSecondary)
                .fixedSize()

                Button("Save") {
                    viewModel.saveRecordedCombination()
                }
                .buttonStyle(.pixel)
                .disabled(!viewModel.canSave)
                .opacity(viewModel.canSave ? 1.0 : 0.5)
                .fixedSize()
            }
        }
    }
}

// MARK: - Key Capture View (NSViewRepresentable)

/// 키 캡처를 위한 NSView 래퍼
struct KeyCaptureView: NSViewRepresentable {
    @ObservedObject var viewModel: KeyCombinationSettingsViewModel

    func makeNSView(context: Context) -> KeyCaptureNSView {
        let view = KeyCaptureNSView()
        view.onKeyDown = { [weak viewModel] keyCode, characters, modifiers in
            viewModel?.handleKeyEvent(keyCode: keyCode, characters: characters, modifierFlags: modifiers)
        }
        view.onFlagsChanged = { [weak viewModel] keyCode, isPressed in
            viewModel?.updateShiftState(keyCode: keyCode, isPressed: isPressed)
        }
        return view
    }

    func updateNSView(_ nsView: KeyCaptureNSView, context: Context) {
        // 녹화 모드일 때 포커스
        if viewModel.isRecording {
            DispatchQueue.main.async {
                nsView.window?.makeFirstResponder(nsView)
            }
        }
    }
}

/// 키 이벤트를 캡처하는 NSView
final class KeyCaptureNSView: NSView {

    // MARK: - Callbacks

    var onKeyDown: ((UInt16, String?, NSEvent.ModifierFlags) -> Void)?
    var onFlagsChanged: ((UInt16, Bool) -> Void)?

    // MARK: - Initialization

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        wantsLayer = true
        layer?.cornerRadius = 8
    }

    // MARK: - View Lifecycle

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        // 윈도우에 추가되면 자동으로 포커스 요청
        if window != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.window?.makeFirstResponder(self)
            }
        }
    }

    // MARK: - First Responder

    override var acceptsFirstResponder: Bool { true }

    override func becomeFirstResponder() -> Bool {
        layer?.borderWidth = 2
        layer?.borderColor = NSColor.controlAccentColor.cgColor
        return super.becomeFirstResponder()
    }

    override func resignFirstResponder() -> Bool {
        layer?.borderWidth = 0
        return super.resignFirstResponder()
    }

    // MARK: - Key Events

    override func keyDown(with event: NSEvent) {
        // 수정자 키만 눌린 경우 무시
        let modifiers = event.modifierFlags.intersection([.shift, .control, .option, .command])
        guard !modifiers.isEmpty else {
            // 수정자 없이 키만 누른 경우도 무시 (안전을 위해)
            return
        }

        onKeyDown?(event.keyCode, event.charactersIgnoringModifiers, event.modifierFlags)
    }

    override func flagsChanged(with event: NSEvent) {
        let keyCode = event.keyCode
        let isPressed = event.modifierFlags.contains(.shift)

        // Left Shift (56) 또는 Right Shift (60)인 경우만 처리
        if keyCode == 56 || keyCode == 60 {
            onFlagsChanged?(keyCode, isPressed)
        }
    }
}

// MARK: - Preview

struct KeyRecorderView_Previews: PreviewProvider {
    static var previews: some View {
        KeyRecorderView(viewModel: KeyCombinationSettingsViewModel())
            .padding()
            .frame(width: 350)
    }
}
