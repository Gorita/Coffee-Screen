import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// 락스크린 커스텀 에디터 뷰 (Draft 상태 세션 관리 및 Back/Save 분리)
struct LockScreenEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var settingsManager = LockScreenSettingsManager.shared
    @StateObject private var dummyShieldViewModel = ShieldViewModel()

    /// 에디터 세션 동안만 사용하는 임시 레이아웃 상태 (Draft State)
    @State private var draftLayout: LockScreenLayout = LockScreenLayout()

    @State private var selectedTab: EditorTab = .background
    @State private var selectedStickerId: UUID?

    private let pixelFont = "Silkscreen-Regular"

    enum EditorTab: String, CaseIterable, Identifiable {
        case background = "Background"
        case stickers = "Stickers"
        case widgets = "Widgets"
        case unlockWindow = "Unlock Box"

        var id: String { rawValue }

        var iconName: String {
            switch self {
            case .background: return "photo.fill"
            case .stickers: return "face.smiling.fill"
            case .widgets: return "clock.fill"
            case .unlockWindow: return "lock.rectangle.stack.fill"
            }
        }
    }

    enum ImagePickerMode {
        case background
        case sticker
    }

    var body: some View {
        VStack(spacing: 0) {
            // 상단 헤더 (좌측: Back, 우측: Save)
            HStack {
                // 뒤로가기 (취소 & 기존 설정 유지)
                Button {
                    print("[DEBUG][LockScreenEditorView] 'Back' clicked. Discarding draft changes...")
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                            .font(.custom(pixelFont, size: 12))
                    }
                }
                .buttonStyle(.pixelSecondary)

                Spacer()

                // 타이틀
                HStack(spacing: 8) {
                    Image(systemName: "paintpalette.fill")
                    Text("Lock Screen Customizer")
                        .font(.custom(pixelFont, size: 14))
                }
                .foregroundStyle(Color.coffeeDark)

                Spacer()

                // 저장 (확정 영구 저장)
                Button("Save") {
                    print("[DEBUG][LockScreenEditorView] 'Save' clicked. Committing draft layout...")
                    saveAndApplyDraft()
                }
                .buttonStyle(.pixel)
            }
            .padding(16)
            .background(Color.coffeeCream.opacity(0.4))

            Divider()

            // 메인 뷰 (좌: 실제 디스플레이 비율 실시간 프리뷰, 우: 컨트롤 패널)
            HStack(spacing: 0) {
                // 좌측: 실제 디스플레이(16:10 / 16:9) 비율에 완벽히 정렬된 캔버스
                VStack {
                    Spacer()
                    previewCanvasArea
                        .aspectRatio(16/10, contentMode: .fit)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(Color.coffeeBrown.opacity(0.4), lineWidth: 2)
                        )
                        .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 6)
                        .padding(20)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.85))

                Divider()

                // 우측: 컨트롤 패널
                VStack(spacing: 0) {
                    // 탭 바 (4분할 균등 & 텍스트 줄바꿈 방지)
                    HStack(spacing: 4) {
                        ForEach(EditorTab.allCases) { tab in
                            Button {
                                selectedTab = tab
                            } label: {
                                HStack(spacing: 2) {
                                    Image(systemName: tab.iconName)
                                        .font(.system(size: 10))
                                    Text(tab.rawValue)
                                        .font(.custom(pixelFont, size: 8))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.5)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 2)
                                .padding(.vertical, 8)
                                .background(selectedTab == tab ? Color.coffeeBrown : Color.clear)
                                .foregroundStyle(selectedTab == tab ? Color.white : Color.coffeeDark)
                                .cornerRadius(4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(6)
                    .background(Color.coffeeCream.opacity(0.2))

                    Divider()

                    // 탭별 컨트롤 패널
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            switch selectedTab {
                            case .background:
                                backgroundControlSection
                            case .stickers:
                                stickersControlSection
                            case .widgets:
                                widgetsControlSection
                            case .unlockWindow:
                                unlockWindowControlSection
                            }
                        }
                        .padding(16)
                    }
                }
                .frame(width: 320)
                .background(Color.coffeeCream.opacity(0.1))
            }
        }
        .frame(minWidth: 880, minHeight: 560)
        .onAppear {
            // 에디터 열릴 때 기존 레이아웃을 draftLayout으로 복사
            self.draftLayout = settingsManager.layout
            print("[DEBUG][LockScreenEditorView] Editor opened. Initialized draftLayout from settingsManager.")
        }
    }

    // MARK: - Save Action

    private func saveAndApplyDraft() {
        settingsManager.layout = draftLayout
        settingsManager.saveLayout()
        dismiss()
    }

    // MARK: - Preview Canvas Area (Draft Layout 기반 렌더링)

    private var previewCanvasArea: some View {
        GeometryReader { geometry in
            ZStack {
                // 1. 배경 (draftLayout)
                switch draftLayout.backgroundType {
                case .solidColor:
                    draftLayout.backgroundColor
                case .customImage:
                    if let bgPath = draftLayout.backgroundImagePath,
                       let nsImage = settingsManager.loadImage(from: bgPath) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                    } else {
                        Color.black
                    }
                case .vintageGrid:
                    VintageGridBackground()
                case .pixelArt:
                    PixelArtBackground()
                }

                // 2. 스티커 레이어 (draftLayout)
                ForEach(draftLayout.stickers) { sticker in
                    if let nsImage = settingsManager.loadImage(from: sticker.imagePath) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80 * sticker.scale, height: 80 * sticker.scale)
                            .rotationEffect(.degrees(sticker.rotation))
                            .offset(x: sticker.x * (geometry.size.width / 1000.0), y: sticker.y * (geometry.size.height / 700.0))
                            .overlay(
                                Rectangle()
                                    .strokeBorder(selectedStickerId == sticker.id ? Color.yellow : Color.clear, lineWidth: 2)
                            )
                            .onTapGesture {
                                selectedStickerId = sticker.id
                            }
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        selectedStickerId = sticker.id
                                        updateStickerPosition(id: sticker.id, translation: value.translation)
                                    }
                            )
                    }
                }

                // 3. 중앙 잠금 창 미리보기 오버레이 (draftLayout)
                let config = draftLayout.unlockWindowConfig
                VStack {
                    Spacer()
                    UnlockView(viewModel: dummyShieldViewModel)
                        .padding(20)
                        .background(previewUnlockWindowBackground(style: config.style, opacity: config.opacity))
                        .shadow(color: config.style == .none ? .clear : .black.opacity(0.5), radius: 16, x: 0, y: 8)
                        .scaleEffect(geometry.size.height / 750.0)
                        .offset(x: config.xOffset * (geometry.size.width / 1000.0), y: config.yOffset * (geometry.size.height / 700.0))
                    Spacer()
                }

                // 4. 위젯 레이어 (draftLayout)
                ZStack {
                    if draftLayout.clockConfig.isEnabled {
                        Text("12:34:56")
                            .font(.custom(pixelFont, size: draftLayout.clockConfig.fontSize * (geometry.size.height / 750.0)))
                            .foregroundStyle(draftLayout.clockConfig.fontColor)
                            .shadow(color: .black.opacity(0.8), radius: 6, x: 0, y: 3)
                            .offset(x: draftLayout.clockConfig.x * (geometry.size.width / 1000.0), y: draftLayout.clockConfig.y * (geometry.size.height / 700.0))
                    }

                    if draftLayout.infoMessageConfig.isEnabled {
                        let textToDisplay = (draftLayout.infoMessageConfig.text?.isEmpty == false)
                            ? draftLayout.infoMessageConfig.text!
                            : String(localized: "Shield.Message", defaultValue: "System Protected by Coffee-Screen")
                        Text(textToDisplay)
                            .font(.custom(pixelFont, size: draftLayout.infoMessageConfig.fontSize * (geometry.size.height / 750.0)))
                            .foregroundStyle(draftLayout.infoMessageConfig.fontColor)
                            .shadow(color: .black.opacity(0.8), radius: 4, x: 0, y: 2)
                            .offset(x: draftLayout.infoMessageConfig.x * (geometry.size.width / 1000.0), y: draftLayout.infoMessageConfig.y * (geometry.size.height / 700.0))
                    }
                }
            }
            .clipped()
        }
    }

    @ViewBuilder
    private func previewUnlockWindowBackground(style: UnlockWindowStyle, opacity: Double) -> some View {
        switch style {
        case .glassmorphic:
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(opacity))
                .background(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                )
        case .solidBlack:
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(opacity))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.white.opacity(0.3), lineWidth: 2)
                )
        case .none:
            Color.clear
        }
    }

    // MARK: - Background Control Section ($draftLayout 바인딩)

    private var backgroundControlSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Background Type")
                .font(.custom(pixelFont, size: 12))
                .foregroundStyle(Color.coffeeDark)

            Picker("", selection: $draftLayout.backgroundType) {
                ForEach(BackgroundType.allCases) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(.radioGroup)

            if draftLayout.backgroundType == .solidColor {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Background Color")
                        .font(.custom(pixelFont, size: 10))
                    ColorPicker("Pick Color", selection: Binding(
                        get: { draftLayout.backgroundColor },
                        set: { draftLayout.backgroundColorHex = $0.toHex() }
                    ))
                }
            }

            if draftLayout.backgroundType == .customImage {
                VStack(alignment: .leading, spacing: 8) {
                    Button("Select Image File...") {
                        print("[DEBUG][LockScreenEditorView] Select Custom Background Image button clicked.")
                        selectImageFile(for: .background)
                    }
                    .buttonStyle(.pixelSecondary)

                    if let path = draftLayout.backgroundImagePath {
                        Text("Selected: \(URL(fileURLWithPath: path).lastPathComponent)")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                }
            }
        }
    }

    // MARK: - Stickers Control Section ($draftLayout 바인딩)

    private var stickersControlSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button("Add Sticker / Image...") {
                print("[DEBUG][LockScreenEditorView] 'Add Sticker / Image' button clicked.")
                selectImageFile(for: .sticker)
            }
            .buttonStyle(.pixelSecondary)

            Divider()

            if draftLayout.stickers.isEmpty {
                Text("No stickers added.")
                    .font(.caption)
                    .foregroundStyle(.gray)
            } else {
                ForEach($draftLayout.stickers) { $sticker in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Sticker \(sticker.id.uuidString.prefix(4))")
                                .font(.custom(pixelFont, size: 10))
                            Spacer()
                            Button(role: .destructive) {
                                print("[DEBUG][LockScreenEditorView] Removing sticker from draft: \(sticker.id)")
                                draftLayout.stickers.removeAll { $0.id == sticker.id }
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.plain)
                        }

                        // Scale slider
                        HStack {
                            Text("Scale")
                                .font(.caption)
                            Slider(value: $sticker.scale, in: 0.2...3.0)
                        }

                        // Rotation slider
                        HStack {
                            Text("Rotate")
                                .font(.caption)
                            Slider(value: $sticker.rotation, in: 0...360)
                        }
                    }
                    .padding(10)
                    .background(Color.white.opacity(0.5))
                    .cornerRadius(6)
                }
            }
        }
    }

    // MARK: - Widgets Control Section ($draftLayout 바인딩)

    private var widgetsControlSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Clock Section
            VStack(alignment: .leading, spacing: 10) {
                Toggle("Show Clock Widget", isOn: $draftLayout.clockConfig.isEnabled)
                    .font(.custom(pixelFont, size: 12))

                if draftLayout.clockConfig.isEnabled {
                    ColorPicker("Clock Color", selection: Binding(
                        get: { draftLayout.clockConfig.fontColor },
                        set: { draftLayout.clockConfig.fontColorHex = $0.toHex() }
                    ))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Clock Font Size: \(Int(draftLayout.clockConfig.fontSize))pt")
                            .font(.caption)
                        Slider(value: $draftLayout.clockConfig.fontSize, in: 16...96, step: 2)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Y Offset (Vertical Position)")
                            .font(.caption)
                        Slider(value: $draftLayout.clockConfig.y, in: -350...350)
                    }
                }
            }

            Divider()

            // Info Message Section
            VStack(alignment: .leading, spacing: 10) {
                Toggle("Show Message Widget", isOn: $draftLayout.infoMessageConfig.isEnabled)
                    .font(.custom(pixelFont, size: 12))

                if draftLayout.infoMessageConfig.isEnabled {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Custom Message Text")
                            .font(.caption)
                        TextField("Enter message", text: Binding(
                            get: { draftLayout.infoMessageConfig.text ?? "" },
                            set: { draftLayout.infoMessageConfig.text = $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }

                    ColorPicker("Message Color", selection: Binding(
                        get: { draftLayout.infoMessageConfig.fontColor },
                        set: { draftLayout.infoMessageConfig.fontColorHex = $0.toHex() }
                    ))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Message Font Size: \(Int(draftLayout.infoMessageConfig.fontSize))pt")
                            .font(.caption)
                        Slider(value: $draftLayout.infoMessageConfig.fontSize, in: 10...64, step: 1)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Y Offset (Vertical Position)")
                            .font(.caption)
                        Slider(value: $draftLayout.infoMessageConfig.y, in: -350...350)
                    }
                }
            }
        }
    }

    // MARK: - Unlock Window Control Section ($draftLayout 바인딩)

    private var unlockWindowControlSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Unlock Window Box Style")
                .font(.custom(pixelFont, size: 12))
                .foregroundStyle(Color.coffeeDark)

            Picker("", selection: $draftLayout.unlockWindowConfig.style) {
                ForEach(UnlockWindowStyle.allCases) { style in
                    Text(style.displayName).tag(style)
                }
            }
            .pickerStyle(.radioGroup)

            Divider()

            if draftLayout.unlockWindowConfig.style != .none {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Box Opacity")
                        .font(.caption)
                    Slider(value: $draftLayout.unlockWindowConfig.opacity, in: 0.0...1.0)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Box Y Offset (Vertical Position)")
                    .font(.caption)
                Slider(value: $draftLayout.unlockWindowConfig.yOffset, in: -350...350)
            }
        }
    }

    // MARK: - File Selection Dialog & Gesture Helpers

    private func selectImageFile(for mode: ImagePickerMode) {
        print("[DEBUG][LockScreenEditorView] selectImageFile requested for mode: \(mode)")
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.treatsFilePackagesAsDirectories = false

        if #available(macOS 11.0, *) {
            panel.allowedContentTypes = [UTType.image, UTType.png, UTType.jpeg, UTType.gif]
        } else {
            panel.allowedFileTypes = ["png", "jpg", "jpeg", "gif", "heic", "tiff"]
        }

        NSApp.activate(ignoringOtherApps: true)

        print("[DEBUG][LockScreenEditorView] Displaying NSOpenPanel file dialog...")
        panel.begin { response in
            print("[DEBUG][LockScreenEditorView] NSOpenPanel closed with response: \(response == .OK ? "OK" : "CANCEL")")
            if response == .OK, let selectedURL = panel.url {
                print("[DEBUG][LockScreenEditorView] User selected file URL: \(selectedURL.path)")
                Task { @MainActor in
                    if let savedPath = settingsManager.importImageToSandbox(selectedURL) {
                        if mode == .background {
                            print("[DEBUG][LockScreenEditorView] Setting draft background image...")
                            draftLayout.backgroundImagePath = savedPath
                            draftLayout.backgroundType = .customImage
                        } else {
                            print("[DEBUG][LockScreenEditorView] Adding sticker to draft...")
                            let newItem = StickerItem(imagePath: savedPath, x: 0, y: 0, scale: 1.0, rotation: 0.0)
                            draftLayout.stickers.append(newItem)
                        }
                    }
                }
            }
        }
    }

    private func updateStickerPosition(id: UUID, translation: CGSize) {
        if let index = draftLayout.stickers.firstIndex(where: { $0.id == id }) {
            draftLayout.stickers[index].x += translation.width * 0.2
            draftLayout.stickers[index].y += translation.height * 0.2
        }
    }
}

#Preview {
    LockScreenEditorView()
}
