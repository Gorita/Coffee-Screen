import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// 플로팅 패널 조작 뷰 (전체 화면 라이브 프리뷰 연동)
struct FloatingControlPanelView: View {
    @ObservedObject var editorController: LockScreenEditorWindowController
    @ObservedObject private var settingsManager = LockScreenSettingsManager.shared

    @State private var selectedTab: EditorTab = .background
    @State private var selectedStickerId: UUID?
    @State private var isAutoRemoveBackground: Bool = true

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
            // 상단 헤더 (← Back / Save)
            HStack {
                Button {
                    print("[DEBUG][FloatingControlPanelView] 'Back' clicked. Discarding changes...")
                    editorController.stopEditing(save: false)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                            .font(.custom(pixelFont, size: 10))
                    }
                }
                .buttonStyle(.pixelSecondary)

                Spacer()

                Text("LIVE CUSTOMIZER")
                    .font(.custom(pixelFont, size: 11))
                    .foregroundStyle(Color.coffeeDark)

                Spacer()

                Button("Save") {
                    print("[DEBUG][FloatingControlPanelView] 'Save' clicked. Committing layout...")
                    editorController.stopEditing(save: true)
                }
                .buttonStyle(.pixel)
            }
            .padding(12)
            .background(Color.coffeeCream.opacity(0.4))

            Divider()

            // 탭 바 (4분할 균등)
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
                .padding(14)
            }
        }
        .background(Color.coffeeCream.opacity(0.1))
    }

    // MARK: - Preset Color Palette
    private let presetColors: [(name: String, hex: String)] = [
        ("Black", "#000000"),
        ("Charcoal", "#1A1A1A"),
        ("Espresso", "#2C1D11"),
        ("Navy", "#1B2A4A"),
        ("Pine", "#1A2F25"),
        ("Plum", "#361D2E"),
        ("Latte", "#4A3525"),
        ("Slate", "#2E282A")
    ]

    // MARK: - Background Control Section

    private var backgroundControlSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Background Type")
                .font(.custom(pixelFont, size: 11))
                .foregroundStyle(Color.coffeeDark)

            Picker("", selection: Binding(
                get: { editorController.draftLayout.backgroundType },
                set: { editorController.draftLayout.backgroundType = $0 }
            )) {
                ForEach(BackgroundType.allCases) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(.radioGroup)

            Divider()

            // 1. Solid Color 옵션 & 추천 색상 칩
            if editorController.draftLayout.backgroundType == .solidColor {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Recommended Color Palettes")
                        .font(.custom(pixelFont, size: 10))
                        .foregroundStyle(Color.coffeeDark)

                    // 추천 컬러 칩 8종 (4x2 그리드)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 6) {
                        ForEach(presetColors, id: \.hex) { preset in
                            let isSelected = editorController.draftLayout.backgroundColorHex.lowercased() == preset.hex.lowercased()
                            Button {
                                editorController.draftLayout.backgroundColorHex = preset.hex
                            } label: {
                                VStack(spacing: 4) {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color(hex: preset.hex) ?? .black)
                                        .frame(height: 24)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .strokeBorder(isSelected ? Color.yellow : Color.white.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                                        )
                                    Text(preset.name)
                                        .font(.system(size: 8))
                                        .foregroundStyle(isSelected ? Color.coffeeBrown : Color.gray)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    ColorPicker("Custom Picker", selection: Binding(
                        get: { editorController.draftLayout.backgroundColor },
                        set: { editorController.draftLayout.backgroundColorHex = $0.toHex() }
                    ))
                    .font(.caption)
                }
            }

            // 2. Custom Image 옵션 & 최근 이미지 갤러리 & Crop 컨트롤
            if editorController.draftLayout.backgroundType == .customImage {
                VStack(alignment: .leading, spacing: 12) {
                    Button("Select Image File...") {
                        selectImageFile(for: .background)
                    }
                    .buttonStyle(.pixelSecondary)

                    // 최근 적용했던 이미지 갤러리 (History)
                    if !editorController.draftLayout.recentImagePaths.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Recent Image Library")
                                .font(.custom(pixelFont, size: 9))
                                .foregroundStyle(Color.coffeeDark)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(editorController.draftLayout.recentImagePaths, id: \.self) { path in
                                        if let nsImage = settingsManager.loadImage(from: path) {
                                            let isSelected = editorController.draftLayout.backgroundImagePath == path
                                            Button {
                                                editorController.draftLayout.backgroundImagePath = path
                                            } label: {
                                                Image(nsImage: nsImage)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: 44, height: 44)
                                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 6)
                                                            .strokeBorder(isSelected ? Color.yellow : Color.clear, lineWidth: 2)
                                                    )
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Recommended Preset Wallpapers (Dev Terminal, Ghostty ASCII, Summer Horror)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Recommended Preset Wallpapers")
                            .font(.custom(pixelFont, size: 9))
                            .foregroundStyle(Color.coffeeDark)

                        HStack(spacing: 8) {
                            ForEach([
                                (name: "Dev Terminal", resourceName: "preset_dev_terminal"),
                                (name: "Ghostty ASCII", resourceName: "preset_ghostty_ascii"),
                                (name: "Summer Horror", resourceName: "preset_creepy_horror")
                            ], id: \.resourceName) { preset in
                                Button {
                                    print("[DEBUG][LockScreenEditorView] Recommended preset clicked: \(preset.name)")
                                    if let savedPath = settingsManager.importPresetGIFToSandbox(named: preset.resourceName) {
                                        print("[DEBUG][LockScreenEditorView] Draft GIF background path: \(savedPath)")
                                        editorController.draftLayout.backgroundImagePath = savedPath
                                        editorController.draftLayout.backgroundType = .customImage
                                    }
                                } label: {
                                    VStack(spacing: 4) {
                                        let thumbPath = "/Users/mireuk/GeminiCli/Coffee-Screen/CoffeeScreen/Resources/\(preset.resourceName).gif"
                                        if let nsImage = settingsManager.loadImage(from: thumbPath) ?? NSImage(contentsOfFile: thumbPath) {
                                            Image(nsImage: nsImage)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 80, height: 48)
                                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 6)
                                                        .strokeBorder(editorController.draftLayout.backgroundImagePath?.contains(preset.resourceName) == true ? Color.yellow : Color.white.opacity(0.3), lineWidth: editorController.draftLayout.backgroundImagePath?.contains(preset.resourceName) == true ? 2 : 1)
                                                )
                                        } else {
                                            Rectangle()
                                                .fill(Color.gray.opacity(0.3))
                                                .frame(width: 80, height: 48)
                                                .cornerRadius(6)
                                        }
                                        Text(preset.name)
                                            .font(.system(size: 8))
                                            .foregroundStyle(editorController.draftLayout.backgroundImagePath?.contains(preset.resourceName) == true ? Color.coffeeBrown : Color.gray)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Divider()

                    // Image Content Mode (Fill / Fit)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Image Display Mode")
                            .font(.caption)
                        Picker("", selection: $editorController.draftLayout.imageContentMode) {
                            ForEach(ImageContentMode.allCases) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    // Image Crop & Scale / Position Sliders
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Crop Zoom Scale")
                                .font(.caption)
                            Spacer()
                            Text("\(String(format: "%.1f", editorController.draftLayout.imageScale))x")
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }
                        Slider(value: $editorController.draftLayout.imageScale, in: 1.0...2.5, step: 0.1)

                        HStack {
                            Text("Position X")
                                .font(.caption)
                            Slider(value: $editorController.draftLayout.imageOffsetX, in: -400...400)
                        }

                        HStack {
                            Text("Position Y")
                                .font(.caption)
                            Slider(value: $editorController.draftLayout.imageOffsetY, in: -400...400)
                        }

                        Button("Reset Crop & Position") {
                            editorController.draftLayout.imageScale = 1.0
                            editorController.draftLayout.imageOffsetX = 0
                            editorController.draftLayout.imageOffsetY = 0
                        }
                        .font(.caption)
                        .buttonStyle(.plain)
                        .foregroundStyle(Color.blue)
                    }
                }
            }
        }
    }

    // MARK: - Preset Sticker Icons Pack
    private let presetStickerIcons: [(name: String, icon: String)] = [
        ("Heart", "heart.fill")
    ]

    // MARK: - Stickers Control Section

    private var stickersControlSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            // 1. 추천 스티커 팩 (Preset Sticker Pack)
            VStack(alignment: .leading, spacing: 8) {
                Text("Preset Sticker Pack")
                    .font(.custom(pixelFont, size: 10))
                    .foregroundStyle(Color.coffeeDark)

                HStack(spacing: 12) {
                    // (1) Heart 이모티콘 스티커
                    ForEach(presetStickerIcons, id: \.icon) { preset in
                        Button {
                            let newItem = StickerItem(systemIconName: preset.icon, name: preset.name, x: -250, y: -250, scale: 1.0, rotation: 0.0)
                            editorController.draftLayout.stickers.append(newItem)
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: preset.icon)
                                    .font(.system(size: 18))
                                    .foregroundStyle(Color.red)
                                    .frame(width: 44, height: 40)
                                    .background(Color.white)
                                    .cornerRadius(6)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .strokeBorder(Color.red.opacity(0.3), lineWidth: 1)
                                    )
                                Text(preset.name)
                                    .font(.system(size: 8))
                                    .foregroundStyle(Color.gray)
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    // (2) 생성된 픽셀 아트 커피 스티커 (Pixel Coffee Sticker)
                    Button {
                        let sampleURL = Bundle.main.url(forResource: "sample_pixel_coffee", withExtension: "jpg") ?? Bundle.main.url(forResource: "sample_pixel_coffee", withExtension: "png")
                        if let validURL = sampleURL,
                           let savedPath = settingsManager.importImageToSandbox(validURL) {
                            var finalPath = savedPath
                            var bgRemoved = false
                            if isAutoRemoveBackground,
                               let rawImg = settingsManager.loadImage(from: savedPath),
                               let cutoutImg = StickerBackgroundRemover.removeBackground(from: rawImg),
                               let cutoutPath = settingsManager.saveNSImageToSandbox(cutoutImg, filename: "cutout_\(UUID().uuidString).png") {
                                finalPath = cutoutPath
                                bgRemoved = true
                            }
                            let newItem = StickerItem(
                                imagePath: finalPath,
                                name: "Pixel Coffee",
                                x: -250,
                                y: -250,
                                scale: 1.0,
                                rotation: 0.0,
                                style: .whiteBorder,
                                isBackgroundRemoved: bgRemoved
                            )
                            editorController.draftLayout.stickers.append(newItem)
                        } else {
                            let newItem = StickerItem(systemIconName: "cup.and.saucer.fill", name: "Coffee Icon", x: -250, y: -250, scale: 1.0, rotation: 0.0)
                            editorController.draftLayout.stickers.append(newItem)
                        }
                    } label: {
                        VStack(spacing: 4) {
                            if let sampleURL = Bundle.main.url(forResource: "sample_pixel_coffee", withExtension: "jpg"),
                               let nsImg = NSImage(contentsOf: sampleURL) {
                                Image(nsImage: nsImg)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 44, height: 40)
                                    .cornerRadius(6)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .strokeBorder(Color.coffeeBrown.opacity(0.4), lineWidth: 1)
                                    )
                            } else {
                                Image(systemName: "cup.and.saucer.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(Color.coffeeBrown)
                                    .frame(width: 44, height: 40)
                                    .background(Color.white)
                                    .cornerRadius(6)
                            }
                            Text("Pixel Coffee")
                                .font(.system(size: 8))
                                .foregroundStyle(Color.gray)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider()

            // 2. 커스텀 스티커 이미지 파일 추가 (AI 배경 제거 토글 포함)
            VStack(alignment: .leading, spacing: 8) {
                Toggle("Auto Remove Background (AI Cutout)", isOn: $isAutoRemoveBackground)
                    .toggleStyle(.checkbox)
                    .font(.caption)
                    .foregroundStyle(Color.coffeeDark)

                HStack {
                    Button("Add Custom Image File...") {
                        selectImageFile(for: .sticker)
                    }
                    .buttonStyle(.pixelSecondary)

                    Spacer()

                    if !editorController.draftLayout.stickers.isEmpty {
                        Button(role: .destructive) {
                            editorController.draftLayout.stickers.removeAll()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "trash.fill")
                                Text("Clear All")
                            }
                            .font(.caption)
                            .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Divider()

            // 3. 스티커 목록 및 상세 컨트롤
            if editorController.draftLayout.stickers.isEmpty {
                Text("No stickers on screen.")
                    .font(.caption)
                    .foregroundStyle(.gray)
            } else {
                ForEach($editorController.draftLayout.stickers) { $sticker in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            if let iconName = sticker.systemIconName {
                                Image(systemName: iconName)
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.coffeeBrown)
                            } else {
                                Image(systemName: "photo")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.gray)
                            }
                            Text(sticker.name.isEmpty ? "Sticker" : sticker.name)
                                .font(.custom(pixelFont, size: 10))

                            Spacer()

                            Button(role: .destructive) {
                                editorController.draftLayout.stickers.removeAll { $0.id == sticker.id }
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                        }

                        // 스티커 스타일 선택 (White Border, Clean, Polaroid)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Sticker Style Frame")
                                .font(.caption)
                            Picker("", selection: $sticker.style) {
                                ForEach(StickerStyle.allCases) { style in
                                    Text(style.displayName).tag(style)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        // 퀵 위치 배치 버튼 (Left Top, Center Top, Right Top)
                        HStack(spacing: 6) {
                            Button("Top Left") {
                                sticker.x = -350
                                sticker.y = -280
                            }
                            .font(.system(size: 9))

                            Button("Top Center") {
                                sticker.x = 0
                                sticker.y = -320
                            }
                            .font(.system(size: 9))

                            Button("Top Right") {
                                sticker.x = 350
                                sticker.y = -280
                            }
                            .font(.system(size: 9))
                        }
                        .buttonStyle(.pixelSecondary)

                        // Position X / Y Sliders (수치 명확화)
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Position X (Horizontal)")
                                    .font(.caption)
                                Spacer()
                                Text("\(Int(sticker.x))px")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                            }
                            Slider(value: $sticker.x, in: -700...700, step: 5)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Position Y (Vertical)")
                                    .font(.caption)
                                Spacer()
                                Text("\(Int(sticker.y))px")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                            }
                            Slider(value: $sticker.y, in: -500...500, step: 5)
                        }

                        // Scale slider
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Size Scale")
                                    .font(.caption)
                                Spacer()
                                Text("\(String(format: "%.1f", sticker.scale))x")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                            }
                            Slider(value: $sticker.scale, in: 0.2...3.0, step: 0.1)
                        }

                        // Rotation slider
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Rotate")
                                    .font(.caption)
                                Spacer()
                                Text("\(Int(sticker.rotation))°")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                            }
                            Slider(value: $sticker.rotation, in: 0...360, step: 5)
                        }
                    }
                    .padding(10)
                    .background(Color.white.opacity(0.6))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(Color.coffeeBrown.opacity(0.3), lineWidth: 1)
                    )
                }
            }
        }
    }

    // MARK: - Widgets Control Section

    private var widgetsControlSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Clock Section
            VStack(alignment: .leading, spacing: 10) {
                Toggle("Show Clock Widget", isOn: $editorController.draftLayout.clockConfig.isEnabled)
                    .font(.custom(pixelFont, size: 11))

                if editorController.draftLayout.clockConfig.isEnabled {
                    ColorPicker("Clock Color", selection: Binding(
                        get: { editorController.draftLayout.clockConfig.fontColor },
                        set: { editorController.draftLayout.clockConfig.fontColorHex = $0.toHex() }
                    ))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Clock Font Size: \(Int(editorController.draftLayout.clockConfig.fontSize))pt")
                            .font(.caption)
                        Slider(value: $editorController.draftLayout.clockConfig.fontSize, in: 16...120, step: 2)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Y Offset (Vertical Position)")
                            .font(.caption)
                        Slider(value: $editorController.draftLayout.clockConfig.y, in: -500...500)
                    }
                }
            }

            Divider()

            // Info Message Section
            VStack(alignment: .leading, spacing: 10) {
                Toggle("Show Message Widget", isOn: $editorController.draftLayout.infoMessageConfig.isEnabled)
                    .font(.custom(pixelFont, size: 11))

                if editorController.draftLayout.infoMessageConfig.isEnabled {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Custom Message Text")
                            .font(.caption)
                        TextField("Enter message", text: Binding(
                            get: { editorController.draftLayout.infoMessageConfig.text ?? "" },
                            set: { editorController.draftLayout.infoMessageConfig.text = $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }

                    ColorPicker("Message Color", selection: Binding(
                        get: { editorController.draftLayout.infoMessageConfig.fontColor },
                        set: { editorController.draftLayout.infoMessageConfig.fontColorHex = $0.toHex() }
                    ))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Message Font Size: \(Int(editorController.draftLayout.infoMessageConfig.fontSize))pt")
                            .font(.caption)
                        Slider(value: $editorController.draftLayout.infoMessageConfig.fontSize, in: 10...80, step: 1)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Y Offset (Vertical Position)")
                            .font(.caption)
                        Slider(value: $editorController.draftLayout.infoMessageConfig.y, in: -500...500)
                    }
                }
            }
        }
    }

    // MARK: - Unlock Window Control Section

    private var unlockWindowControlSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Unlock Window Box Style")
                .font(.custom(pixelFont, size: 11))
                .foregroundStyle(Color.coffeeDark)

            Picker("", selection: $editorController.draftLayout.unlockWindowConfig.style) {
                ForEach(UnlockWindowStyle.allCases) { style in
                    Text(style.displayName).tag(style)
                }
            }
            .pickerStyle(.radioGroup)

            Divider()

            if editorController.draftLayout.unlockWindowConfig.style != .none {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Box Opacity")
                        .font(.caption)
                    Slider(value: $editorController.draftLayout.unlockWindowConfig.opacity, in: 0.0...1.0)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Box Y Offset (Vertical Position)")
                    .font(.caption)
                Slider(value: $editorController.draftLayout.unlockWindowConfig.yOffset, in: -500...500)
            }
        }
    }

    // MARK: - File Selection Dialog Helper (최상단 Window Level 적용)

    private func selectImageFile(for mode: ImagePickerMode) {
        print("[DEBUG][FloatingControlPanelView] Opening NSOpenPanel file picker...")
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

        // 전체 화면 프리뷰 윈도우 및 플로팅 패널보다 더 높은 Z-Index 최상단 팝업 레벨로 지정
        panel.level = NSWindow.Level(Int(CGWindowLevelForKey(.popUpMenuWindow)) + 10)
        
        NSApp.activate(ignoringOtherApps: true)
        panel.orderFrontRegardless()

        panel.begin { response in
            print("[DEBUG][FloatingControlPanelView] NSOpenPanel response: \(response == .OK ? "OK" : "CANCEL")")
            if response == .OK, let selectedURL = panel.url {
                print("[DEBUG][FloatingControlPanelView] Selected image URL: \(selectedURL.path)")
                Task { @MainActor in
                    if let savedPath = settingsManager.importImageToSandbox(selectedURL) {
                        if mode == .background {
                            editorController.draftLayout.backgroundImagePath = savedPath
                            editorController.draftLayout.backgroundType = .customImage
                        } else {
                            var finalPath = savedPath
                            var backgroundRemoved = false
                            if isAutoRemoveBackground,
                               let rawImage = LockScreenSettingsManager.shared.loadImage(from: savedPath),
                               let cutoutImage = StickerBackgroundRemover.removeBackground(from: rawImage),
                               let cutoutPath = LockScreenSettingsManager.shared.saveNSImageToSandbox(cutoutImage, filename: "cutout_\(UUID().uuidString).png") {
                                finalPath = cutoutPath
                                backgroundRemoved = true
                            }
                            let newItem = StickerItem(
                                imagePath: finalPath,
                                name: selectedURL.deletingPathExtension().lastPathComponent,
                                x: -250,
                                y: -250,
                                scale: 1.0,
                                rotation: 0.0,
                                style: .whiteBorder,
                                isBackgroundRemoved: backgroundRemoved
                            )
                            editorController.draftLayout.stickers.append(newItem)
                        }
                    }
                }
            }
        }
    }
}
