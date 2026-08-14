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
        case background   = "Background"
        case stickers     = "Stickers"
        case widgets      = "Widgets"
        case unlockWindow = "Unlock Box"
        case bulletinBoard = "알림판"

        var id: String { rawValue }

        var iconName: String {
            switch self {
            case .background:   return "photo.fill"
            case .stickers:     return "face.smiling.fill"
            case .widgets:      return "clock.fill"
            case .unlockWindow: return "lock.rectangle.stack.fill"
            case .bulletinBoard: return "bell.badge.fill"
            }
        }
    }

    enum ImagePickerMode {
        case background
        case sticker
        case headerIcon
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
                        .contentShape(Rectangle())
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
                    case .bulletinBoard:
                        bulletinBoardControlSection
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

                    // Recommended Preset Wallpapers (Dev Terminal, Ghostty ASCII, Interactive Typing, Pixel Dog, Summer Horror)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Recommended Preset Wallpapers")
                            .font(.custom(pixelFont, size: 9))
                            .foregroundStyle(Color.coffeeDark)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach([
                                    (name: "Dev Terminal", resourceName: "preset_dev_terminal"),
                                    (name: "Ghostty ASCII", resourceName: "preset_ghostty_ascii"),
                                    (name: "Interactive Typing", resourceName: "preset_dev_typing"),
                                    (name: "Pixel Dog", resourceName: "preset_pixel_dog"),
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
                                            let thumbPath = Bundle.main.path(forResource: preset.resourceName, ofType: "gif") ?? "/Users/mireuk/GeminiCli/Coffee-Screen/CoffeeScreen/Resources/\(preset.resourceName).gif"
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
        VStack(alignment: .leading, spacing: 16) {
            // 1. Box Style & Opacity (라디오 버튼 목록 형태 .radioGroup)
            VStack(alignment: .leading, spacing: 10) {
                Text("Unlock Window Box Style")
                    .font(.custom(pixelFont, size: 11))
                    .foregroundStyle(Color.coffeeDark)

                Picker("", selection: $editorController.draftLayout.unlockWindowConfig.style) {
                    ForEach(UnlockWindowStyle.allCases) { style in
                        Text(style.displayName).tag(style)
                    }
                }
                .pickerStyle(.radioGroup)

                if editorController.draftLayout.unlockWindowConfig.style != .none {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Box Opacity: \(Int(editorController.draftLayout.unlockWindowConfig.opacity * 100))%")
                            .font(.caption)
                        Slider(value: $editorController.draftLayout.unlockWindowConfig.opacity, in: 0.0...1.0)
                    }
                }
            }

            Divider()

            // 2. Position X / Y Offset & Center Align Button
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Position Offset")
                        .font(.custom(pixelFont, size: 11))
                        .foregroundStyle(Color.coffeeDark)
                    Spacer()
                    Button("Center Align Window") {
                        editorController.draftLayout.unlockWindowConfig.xOffset = 0
                        editorController.draftLayout.unlockWindowConfig.yOffset = 0
                    }
                    .font(.system(size: 9))
                    .buttonStyle(.pixelSecondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Box X Offset (Horizontal)")
                            .font(.caption)
                        Spacer()
                        Text("\(Int(editorController.draftLayout.unlockWindowConfig.xOffset))px")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                    Slider(value: $editorController.draftLayout.unlockWindowConfig.xOffset, in: -700...700, step: 5)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Box Y Offset (Vertical)")
                            .font(.caption)
                        Spacer()
                        Text("\(Int(editorController.draftLayout.unlockWindowConfig.yOffset))px")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                    Slider(value: $editorController.draftLayout.unlockWindowConfig.yOffset, in: -500...500, step: 5)
                }
            }

            Divider()

            // 3. Header Icon Customization
            VStack(alignment: .leading, spacing: 10) {
                Text("Header Icon")
                    .font(.custom(pixelFont, size: 11))
                    .foregroundStyle(Color.coffeeDark)

                Picker("Icon Style", selection: $editorController.draftLayout.unlockWindowConfig.headerIcon) {
                    ForEach(UnlockHeaderIcon.allCases) { icon in
                        Text(icon.displayName).tag(icon)
                    }
                }
                .pickerStyle(.radioGroup)

                if editorController.draftLayout.unlockWindowConfig.headerIcon == .customImage {
                    // Custom Image 선택 시 파일 피커 버튼
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Button("Select Image...") {
                                selectImageFile(for: .headerIcon)
                            }
                            .buttonStyle(.pixelSecondary)
                            .font(.system(size: 10))

                            if let path = editorController.draftLayout.unlockWindowConfig.headerCustomImagePath {
                                Text(URL(fileURLWithPath: path).lastPathComponent)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                Spacer()
                                Button("✕") {
                                    editorController.draftLayout.unlockWindowConfig.headerCustomImagePath = nil
                                }
                                .font(.caption2)
                                .foregroundStyle(.red)
                                .buttonStyle(.plain)
                            }
                        }
                    }
                } else if editorController.draftLayout.unlockWindowConfig.headerIcon != .none {
                    // SF Symbol 선택 시 색상 피커
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Icon Color")
                                .font(.caption)
                            Spacer()
                            ColorPicker("", selection: Binding(
                                get: { editorController.draftLayout.unlockWindowConfig.headerIconColor },
                                set: { editorController.draftLayout.unlockWindowConfig.headerIconColorHex = $0.toHex() }
                            ))
                        }

                        HStack(spacing: 6) {
                            ForEach([("#FFD700", "Gold"), ("#FFFFFF", "White"), ("#3B82F6", "Blue"), ("#22C55E", "Green"), ("#EF4444", "Red"), ("#A855F7", "Purple")], id: \.0) { hex, _ in
                                Circle()
                                    .fill(Color(hex: hex) ?? .yellow)
                                    .frame(width: 18, height: 18)
                                    .overlay(Circle().stroke(Color.gray.opacity(0.4), lineWidth: 1))
                                    .onTapGesture {
                                        editorController.draftLayout.unlockWindowConfig.headerIconColorHex = hex
                                    }
                            }
                        }
                    }
                }
            }

            Divider()

            // 4. Touch ID Button Customization (해당 버튼 하위 위계)
            VStack(alignment: .leading, spacing: 10) {
                Text("Touch ID Button Customization")
                    .font(.custom(pixelFont, size: 11))
                    .foregroundStyle(Color.coffeeDark)

                Picker("Button Style", selection: $editorController.draftLayout.unlockWindowConfig.touchIDButtonStyle) {
                    ForEach(ButtonStyleType.allCases) { style in
                        Text(style.displayName).tag(style)
                    }
                }
                .pickerStyle(.radioGroup)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Touch ID Button Width")
                            .font(.caption)
                        Spacer()
                        Text("\(Int(editorController.draftLayout.unlockWindowConfig.touchIDButtonWidth))pt")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                    Slider(value: $editorController.draftLayout.unlockWindowConfig.touchIDButtonWidth, in: 120...220, step: 5)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Touch ID Button Opacity")
                            .font(.caption)
                        Spacer()
                        Text("\(Int(editorController.draftLayout.unlockWindowConfig.touchIDButtonOpacity * 100))%")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                    Slider(value: $editorController.draftLayout.unlockWindowConfig.touchIDButtonOpacity, in: 0.2...1.0, step: 0.05)
                }

                // Touch ID 전용 색상 및 하위 프리셋 칩
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Touch ID Button Color")
                            .font(.caption)
                        Spacer()
                        ColorPicker("", selection: Binding(
                            get: { editorController.draftLayout.unlockWindowConfig.touchIDButtonColor },
                            set: { editorController.draftLayout.unlockWindowConfig.touchIDButtonColorHex = $0.toHex() }
                        ))
                    }

                    HStack(spacing: 6) {
                        ForEach([("#3B82F6", "Blue"), ("#22C55E", "Green"), ("#A855F7", "Purple"), ("#F97316", "Orange"), ("#1F2937", "Dark"), ("#FFFFFF", "White")], id: \.0) { hex, label in
                            Circle()
                                .fill(Color(hex: hex) ?? .blue)
                                .frame(width: 18, height: 18)
                                .overlay(Circle().stroke(Color.gray.opacity(0.4), lineWidth: 1))
                                .onTapGesture {
                                    editorController.draftLayout.unlockWindowConfig.touchIDButtonColorHex = hex
                                }
                        }
                    }
                }
            }

            Divider()

            // 4. PIN Button & Mask Customization (해당 버튼 하위 위계)
            VStack(alignment: .leading, spacing: 10) {
                Text("PIN Input & Button Customization")
                    .font(.custom(pixelFont, size: 11))
                    .foregroundStyle(Color.coffeeDark)

                Picker("PIN Style", selection: $editorController.draftLayout.unlockWindowConfig.pinButtonStyle) {
                    ForEach(PINButtonStyle.allCases) { style in
                        Text(style.displayName).tag(style)
                    }
                }
                .pickerStyle(.radioGroup)

                Picker("Mask Symbol", selection: $editorController.draftLayout.unlockWindowConfig.pinMaskSymbol) {
                    ForEach(PINMaskSymbol.allCases) { symbol in
                        Text("\(symbol.displayName) (\(symbol.rawValue))").tag(symbol)
                    }
                }
                .pickerStyle(.radioGroup)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Confirm Button Width")
                            .font(.caption)
                        Spacer()
                        Text("\(Int(editorController.draftLayout.unlockWindowConfig.pinButtonWidth))pt")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                    Slider(value: $editorController.draftLayout.unlockWindowConfig.pinButtonWidth, in: 120...220, step: 5)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Confirm Button Opacity")
                            .font(.caption)
                        Spacer()
                        Text("\(Int(editorController.draftLayout.unlockWindowConfig.pinConfirmButtonOpacity * 100))%")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                    Slider(value: $editorController.draftLayout.unlockWindowConfig.pinConfirmButtonOpacity, in: 0.2...1.0, step: 0.05)
                }

                // PIN 전용 색상 및 하위 프리셋 칩
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("PIN Confirm Button Color")
                            .font(.caption)
                        Spacer()
                        ColorPicker("", selection: Binding(
                            get: { editorController.draftLayout.unlockWindowConfig.pinConfirmButtonColor },
                            set: { editorController.draftLayout.unlockWindowConfig.pinConfirmButtonColorHex = $0.toHex() }
                        ))
                    }

                    HStack(spacing: 6) {
                        ForEach([("#22C55E", "Green"), ("#3B82F6", "Blue"), ("#F97316", "Orange"), ("#EF4444", "Red"), ("#A855F7", "Purple"), ("#EAB308", "Gold")], id: \.0) { hex, label in
                            Circle()
                                .fill(Color(hex: hex) ?? .green)
                                .frame(width: 18, height: 18)
                                .overlay(Circle().stroke(Color.gray.opacity(0.4), lineWidth: 1))
                                .onTapGesture {
                                    editorController.draftLayout.unlockWindowConfig.pinConfirmButtonColorHex = hex
                                }
                        }
                    }
                }
            }

            Divider()

            // 5. Title & Subtext Customization
            VStack(alignment: .leading, spacing: 12) {
                Text("Title & Text Customization")
                    .font(.custom(pixelFont, size: 11))
                    .foregroundStyle(Color.coffeeDark)

                // 1) 메인 타이틀
                VStack(alignment: .leading, spacing: 6) {
                    Toggle("Show Title Text", isOn: $editorController.draftLayout.unlockWindowConfig.isTitleVisible)
                        .font(.caption)

                    if editorController.draftLayout.unlockWindowConfig.isTitleVisible {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Title Text").font(.caption2).foregroundStyle(.secondary)
                                Spacer()
                            }
                            TextField("Title", text: $editorController.draftLayout.unlockWindowConfig.titleText)
                                .textFieldStyle(.roundedBorder)

                            HStack {
                                Text("Title Color").font(.caption2)
                                Spacer()
                                ColorPicker("", selection: Binding(
                                    get: { Color(hex: editorController.draftLayout.unlockWindowConfig.titleColorHex) ?? .white },
                                    set: { editorController.draftLayout.unlockWindowConfig.titleColorHex = $0.toHex() }
                                ))
                            }

                            HStack {
                                Text("Title Size").font(.caption2)
                                Spacer()
                                Text("\(Int(editorController.draftLayout.unlockWindowConfig.titleFontSize))pt")
                                    .font(.caption2).foregroundStyle(.gray)
                            }
                            Slider(value: $editorController.draftLayout.unlockWindowConfig.titleFontSize, in: 14...40, step: 1)
                        }
                        .padding(.leading, 10)
                    }
                }

                Divider().padding(.vertical, 2)

                // 2) 서브텍스트 (안내 문구)
                VStack(alignment: .leading, spacing: 6) {
                    Toggle("Show Subtext (Subtitle)", isOn: $editorController.draftLayout.unlockWindowConfig.isSubtextVisible)
                        .font(.caption)

                    if editorController.draftLayout.unlockWindowConfig.isSubtextVisible {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Subtext").font(.caption2).foregroundStyle(.secondary)
                                Spacer()
                            }
                            TextField("Subtext", text: $editorController.draftLayout.unlockWindowConfig.subtextText)
                                .textFieldStyle(.roundedBorder)

                            HStack {
                                Text("Subtext Color").font(.caption2)
                                Spacer()
                                ColorPicker("", selection: Binding(
                                    get: { Color(hex: editorController.draftLayout.unlockWindowConfig.subtextColorHex) ?? .gray },
                                    set: { editorController.draftLayout.unlockWindowConfig.subtextColorHex = $0.toHex() }
                                ))
                            }

                            HStack {
                                Text("Subtext Size").font(.caption2)
                                Spacer()
                                Text("\(Int(editorController.draftLayout.unlockWindowConfig.subtextFontSize))pt")
                                    .font(.caption2).foregroundStyle(.gray)
                            }
                            Slider(value: $editorController.draftLayout.unlockWindowConfig.subtextFontSize, in: 9...24, step: 1)
                        }
                        .padding(.leading, 10)
                    }
                }

                Divider().padding(.vertical, 2)

                // 3) 버튼 라벨 텍스트 변경 (Touch ID / PIN 버튼 문구)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Button Labels").font(.system(size: 11, weight: .semibold))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Touch ID Button Text").font(.caption2).foregroundStyle(.secondary)
                        TextField("Touch ID Label", text: $editorController.draftLayout.unlockWindowConfig.touchIDButtonText)
                            .textFieldStyle(.roundedBorder)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("PIN Confirm Button Text").font(.caption2).foregroundStyle(.secondary)
                        TextField("PIN Label", text: $editorController.draftLayout.unlockWindowConfig.pinConfirmButtonText)
                            .textFieldStyle(.roundedBorder)
                    }
                }
            }

            Divider()

            // 6. Switches & Actions
            VStack(alignment: .leading, spacing: 12) {
                Text("Switches & Actions")
                    .font(.custom(pixelFont, size: 11))
                    .foregroundStyle(Color.coffeeDark)

                VStack(alignment: .leading, spacing: 6) {
                    Toggle("Show Mode Switch Button (PIN / Touch ID)", isOn: $editorController.draftLayout.unlockWindowConfig.isModeSwitchButtonVisible)
                        .font(.caption)

                    if editorController.draftLayout.unlockWindowConfig.isModeSwitchButtonVisible {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Use PIN Label").font(.caption2).foregroundStyle(.secondary)
                                Spacer()
                            }
                            TextField("Use PIN", text: $editorController.draftLayout.unlockWindowConfig.usePINText)
                                .textFieldStyle(.roundedBorder)

                            HStack {
                                Text("Use Touch ID Label").font(.caption2).foregroundStyle(.secondary)
                                Spacer()
                            }
                            TextField("Use Touch ID", text: $editorController.draftLayout.unlockWindowConfig.useTouchIDText)
                                .textFieldStyle(.roundedBorder)

                            HStack {
                                Text("Mode Switch Opacity")
                                    .font(.caption2)
                                Spacer()
                                Text("\(Int(editorController.draftLayout.unlockWindowConfig.modeSwitchOpacity * 100))%")
                                    .font(.caption2)
                                    .foregroundStyle(.gray)
                            }
                            Slider(value: $editorController.draftLayout.unlockWindowConfig.modeSwitchOpacity, in: 0.2...1.0, step: 0.05)
                        }
                        .padding(.leading, 10)
                    }
                }

                Toggle("Show Mac Shutdown Button", isOn: $editorController.draftLayout.unlockWindowConfig.isShutdownButtonVisible)
                    .font(.caption)
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
                        } else if mode == .headerIcon {
                            editorController.draftLayout.unlockWindowConfig.headerCustomImagePath = savedPath
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

// MARK: - 알림판 탭 섹션

extension FloatingControlPanelView {
    var bulletinBoardControlSection: some View {
        BulletinBoardEditorSection(editorController: editorController)
    }
}

/// 알림판 설정 에디터 (별도 뷰로 분리하여 @ObservedObject 적용)
struct BulletinBoardEditorSection: View {
    @ObservedObject var editorController: LockScreenEditorWindowController
    @ObservedObject private var bulletinServer = BulletinSocketServer.shared

    private let pixelFont = "Silkscreen-Regular"

    private var config: Binding<BulletinBoardConfig> {
        $editorController.draftLayout.bulletinBoardConfig
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            // MARK: 1. 소켓 서버 활성화 및 상태
            let isEnabled = config.isEnabled.wrappedValue

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center) {
                    Image(systemName: isEnabled ? "bell.badge.fill" : "bell.slash.fill")
                        .font(.title2)
                        .foregroundStyle(isEnabled ? Color.green : Color.gray)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("알림판 소켓 서버")
                            .font(.custom(pixelFont, size: 11))
                            .foregroundStyle(Color.primary)
                        
                        HStack(spacing: 4) {
                            Circle()
                                .fill(isEnabled ? Color.green : Color.secondary)
                                .frame(width: 7, height: 7)
                            
                            if isEnabled {
                                Text("서버 ON")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(Color.green)
                            } else {
                                Text("서버 OFF (스위치를 켜면 작동합니다)")
                                    .font(.system(size: 9.5, weight: .medium))
                                    .foregroundStyle(Color.secondary)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: config.isEnabled)
                        .toggleStyle(.switch)
                        .labelsHidden()
                }

                // MARK: 소켓 경로 및 터미널 전송 사용법 안내 (항상 고대비 노출)
                VStack(alignment: .leading, spacing: 10) {
                    Text("소켓 경로 (Unix Domain Socket)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.primary)

                    HStack(spacing: 6) {
                        Text(editorController.draftLayout.bulletinBoardConfig.socketPath)
                            .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Color.green)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer()
                        
                        // 1. 소켓 경로 단독 복사
                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(
                                editorController.draftLayout.bulletinBoardConfig.socketPath,
                                forType: .string
                            )
                        } label: {
                            HStack(spacing: 3) {
                                Image(systemName: "doc.on.doc").font(.system(size: 8.5))
                                Text("경로 복사").font(.system(size: 9, weight: .bold))
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .cornerRadius(4)
                        }
                        .buttonStyle(.plain)

                        // 2. 에라이전트 전용 프롬프트 종합 복사
                        Button {
                            let socketPath = editorController.draftLayout.bulletinBoardConfig.socketPath
                            let style = editorController.draftLayout.bulletinBoardConfig.displayStyle.displayName
                            let promptText = """
                            [Coffee-Screen 알림판 연동 가이드]
                            작업 완료나 주요 상태 변경 시 아래 Unix Domain Socket으로 메시지를 보내주세요.
                            - 소켓 경로: \(socketPath)
                            - 알림 스타일: \(style)
                            - 메시지 전송 명령어 예시:
                              • 성공: echo '{"text":"[작업명] 완료되었습니다!","level":"success"}' | nc -U \(socketPath)
                              • 에러: echo '{"text":"[작업명] 실패하였습니다.","level":"error"}' | nc -U \(socketPath)
                              • 일반: echo '{"text":"[작업명] 진행 중...","level":"info"}' | nc -U \(socketPath)
                            - 지원 레벨(level): info (파랑), success (초록), warning (주황), error (빨강)
                            """
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(promptText, forType: .string)
                        } label: {
                            HStack(spacing: 3) {
                                Image(systemName: "text.bubble.fill").font(.system(size: 8.5))
                                Text("🤖 에이전트 훅 복사").font(.system(size: 9, weight: .bold))
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(Color.purple)
                            .foregroundStyle(.white)
                            .cornerRadius(4)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(8)
                    .background(Color.black.opacity(0.85))
                    .cornerRadius(6)

                    // 터미널 전송 가이드
                    VStack(alignment: .leading, spacing: 6) {
                        Text("💡 메시지 전송 방법 (터미널 / 외부 스크립트)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.primary)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("# 1. 일반 텍스트 전송")
                                    .font(.system(size: 8.5, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(Color.yellow)
                                Text("echo 'Claude: 빌드 완료' | nc -U \(editorController.draftLayout.bulletinBoardConfig.socketPath)")
                                    .font(.system(size: 8.5, weight: .regular, design: .monospaced))
                                    .foregroundStyle(Color.white)
                                    .textSelection(.enabled)
                            }
                            
                            Divider().background(Color.white.opacity(0.3))

                            VStack(alignment: .leading, spacing: 2) {
                                Text("# 2. 메시지 등급(level) 지정 JSON 전송")
                                    .font(.system(size: 8.5, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(Color.cyan)
                                Text(#"echo '{"text":"성공!","level":"success"}' | nc -U "#
                                     + editorController.draftLayout.bulletinBoardConfig.socketPath)
                                    .font(.system(size: 8.5, weight: .regular, design: .monospaced))
                                    .foregroundStyle(Color.white)
                                    .textSelection(.enabled)
                            }
                        }
                        .padding(8)
                        .background(Color.black.opacity(0.9))
                        .cornerRadius(6)
                    }

                    // MARK: Level(메시지 등급) 명확한 설명
                    VStack(alignment: .leading, spacing: 6) {
                        Text("📌 level(메시지 등급) 종류 안내")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.primary)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Image(systemName: "info.circle.fill").foregroundStyle(Color.blue)
                                Text("info").font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundStyle(Color.blue)
                                Text("— 일반 안내 메시지 (기본값)").font(.system(size: 9)).foregroundStyle(Color.primary)
                            }
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.green)
                                Text("success").font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundStyle(Color.green)
                                Text("— 작업 성공 및 완료 알림").font(.system(size: 9)).foregroundStyle(Color.primary)
                            }
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(Color.orange)
                                Text("warning").font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundStyle(Color.orange)
                                Text("— 주의 및 경고 상태 알림").font(.system(size: 9)).foregroundStyle(Color.primary)
                            }
                            HStack(spacing: 6) {
                                Image(systemName: "xmark.circle.fill").foregroundStyle(Color.red)
                                Text("error").font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundStyle(Color.red)
                                Text("— 에러 및 실패 상태 알림").font(.system(size: 9)).foregroundStyle(Color.primary)
                            }
                        }
                        .padding(8)
                        .background(Color.black.opacity(0.06))
                        .cornerRadius(6)
                    }
                }
            }

            Divider()

            // MARK: 2. 표시 스타일 선택
            VStack(alignment: .leading, spacing: 10) {
                Text("표시 스타일")
                    .font(.custom(pixelFont, size: 11))
                    .foregroundStyle(Color.coffeeDark)

                Picker("", selection: config.displayStyle) {
                    ForEach(BulletinDisplayStyle.allCases) { style in
                        Label(style.displayName, systemImage: style.iconName).tag(style)
                    }
                }
                .pickerStyle(.radioGroup)
            }

            Divider()

            // MARK: 3. 메시지 옵션
            VStack(alignment: .leading, spacing: 10) {
                Text("메시지 옵션")
                    .font(.custom(pixelFont, size: 11))
                    .foregroundStyle(Color.coffeeDark)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("최대 표시 메시지 수").font(.caption)
                        Spacer()
                        Text("\(editorController.draftLayout.bulletinBoardConfig.maxMessages)개")
                            .font(.caption).foregroundStyle(.gray)
                    }
                    Slider(
                        value: Binding(
                            get: { Double(editorController.draftLayout.bulletinBoardConfig.maxMessages) },
                            set: { editorController.draftLayout.bulletinBoardConfig.maxMessages = Int($0) }
                        ),
                        in: 1...10, step: 1
                    )
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("자동 사라짐").font(.caption)
                        Spacer()
                        let dur = editorController.draftLayout.bulletinBoardConfig.autoDismissDuration
                        Text(dur == 0 ? "OFF" : "\(Int(dur))초")
                            .font(.caption).foregroundStyle(.gray)
                    }
                    Slider(value: config.autoDismissDuration, in: 0...30, step: 1)
                    Text("0 = 자동 사라짐 없음")
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }

            // 픽셀 텍스트 전용 옵션
            if editorController.draftLayout.bulletinBoardConfig.displayStyle == .pixelText {
                Divider()
                VStack(alignment: .leading, spacing: 10) {
                    Text("픽셀 텍스트 옵션")
                        .font(.custom(pixelFont, size: 11))
                        .foregroundStyle(Color.coffeeDark)

                    HStack {
                        Text("글자 색상").font(.caption)
                        Spacer()
                        ColorPicker("", selection: Binding(
                            get: { editorController.draftLayout.bulletinBoardConfig.fontColor },
                            set: { editorController.draftLayout.bulletinBoardConfig.fontColorHex = $0.toHex() }
                        ))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("글자 크기").font(.caption)
                            Spacer()
                            Text("\(Int(editorController.draftLayout.bulletinBoardConfig.fontSize))pt")
                                .font(.caption).foregroundStyle(.gray)
                        }
                        Slider(value: config.fontSize, in: 10...48, step: 2)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Y 위치").font(.caption)
                            Spacer()
                            Text("\(Int(editorController.draftLayout.bulletinBoardConfig.positionY))px")
                                .font(.caption).foregroundStyle(.gray)
                        }
                        Slider(value: config.positionY, in: -500...500, step: 5)
                    }
                }
            }

            Divider()

            // MARK: 4. 테스트 & 초기화
            VStack(alignment: .leading, spacing: 8) {
                Text("테스트")
                    .font(.custom(pixelFont, size: 11))
                    .foregroundStyle(Color.coffeeDark)
                HStack(spacing: 8) {
                    Button("테스트 메시지 전송") {
                        bulletinServer.sendTestMessage(
                            style: editorController.draftLayout.bulletinBoardConfig.displayStyle
                        )
                    }
                    .buttonStyle(.pixel)
                    .font(.system(size: 10))

                    Button("메시지 초기화") {
                        bulletinServer.clearMessages()
                    }
                    .buttonStyle(.pixelSecondary)
                    .font(.system(size: 10))
                }
            }

            // MARK: 5. 수신 메시지 히스토리
            if !bulletinServer.messages.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("수신된 메시지")
                            .font(.custom(pixelFont, size: 10))
                            .foregroundStyle(Color.coffeeDark)
                        Spacer()
                        Text("\(bulletinServer.messages.count)개")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                    ForEach(bulletinServer.messages) { msg in
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: msg.level.iconName)
                                .font(.caption2)
                                .foregroundStyle(msg.level.color)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(msg.text)
                                    .font(.caption2)
                                    .foregroundStyle(.primary)
                                    .lineLimit(2)
                                Text(msg.timestamp, style: .time)
                                    .font(.system(size: 8))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.5))
                        .cornerRadius(4)
                    }
                }
            }
        }
    }
}
