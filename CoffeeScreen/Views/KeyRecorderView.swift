import SwiftUI
import AppKit

/// 비상 탈출 키 설정 뷰
struct KeyRecorderView: View {
    @ObservedObject var viewModel: KeyCombinationSettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if viewModel.isRecording {
                recordingView
            } else {
                displayView
            }

            // 메시지 표시
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            if let success = viewModel.successMessage {
                Text(success)
                    .font(.caption)
                    .foregroundStyle(.green)
            }
        }
    }

    // MARK: - Display View

    private var displayView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("key.current", tableName: nil, bundle: .main)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(viewModel.currentKeyDisplay)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.medium)
            }

            Spacer()

            HStack(spacing: 8) {
                Button(String(localized: "key.change")) {
                    viewModel.startRecording()
                }
                .buttonStyle(.bordered)
                .focusEffectDisabled()

                Button(String(localized: "key.reset")) {
                    viewModel.resetToDefault()
                }
                .buttonStyle(.bordered)
                .focusEffectDisabled()
            }
        }
    }

    // MARK: - Recording View

    private var recordingView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("key.recording.instruction", tableName: nil, bundle: .main)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // 키 캡처 영역
            KeyCaptureView(viewModel: viewModel)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(nsColor: .textBackgroundColor))
                        .stroke(Color.accentColor, lineWidth: 2)
                )

            // 녹화된 키 표시
            if !viewModel.recordedKeyDisplay.isEmpty {
                HStack {
                    Text(viewModel.recordedKeyDisplay)
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    if viewModel.bothShiftsPressed {
                        Text("(양쪽 Shift)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // 버튼
            HStack(spacing: 8) {
                Button(String(localized: "cancel")) {
                    viewModel.cancelRecording()
                }
                .buttonStyle(.bordered)
                .focusEffectDisabled()

                Button(String(localized: "save")) {
                    viewModel.saveRecordedCombination()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canSave)
                .focusEffectDisabled()
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
