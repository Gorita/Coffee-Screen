import AppKit
import Foundation
import SwiftUI

/// 락스크린 커스텀 설정 및 샌드박스 자원 관리자
@MainActor
final class LockScreenSettingsManager: ObservableObject {
    static let shared = LockScreenSettingsManager()

    @Published var layout: LockScreenLayout = LockScreenLayout() {
        didSet {
            saveLayout()
        }
    }

    private let fileManager = FileManager.default

    /// Application Support/Coffee-Screen 경로
    var settingsDirectory: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("Coffee-Screen", isDirectory: true)
    }

    /// Application Support/Coffee-Screen/CustomAssets 경로
    var customAssetsDirectory: URL {
        return settingsDirectory.appendingPathComponent("CustomAssets", isDirectory: true)
    }

    /// JSON 파일 경로
    private var layoutFilePath: URL {
        return settingsDirectory.appendingPathComponent("lockscreen_layout.json")
    }

    init() {
        print("[DEBUG][LockScreenSettingsManager] Initializing LockScreenSettingsManager...")
        createDirectoriesIfNeeded()
        loadLayout()
    }

    // MARK: - Directory Management

    private func createDirectoriesIfNeeded() {
        print("[DEBUG][LockScreenSettingsManager] Checking customAssetsDirectory: \(customAssetsDirectory.path)")
        if !fileManager.fileExists(atPath: customAssetsDirectory.path) {
            do {
                try fileManager.createDirectory(at: customAssetsDirectory, withIntermediateDirectories: true)
                print("[DEBUG][LockScreenSettingsManager] Created customAssetsDirectory successfully.")
            } catch {
                print("[DEBUG][LockScreenSettingsManager] ERROR creating directory: \(error)")
            }
        }
    }

    // MARK: - JSON Persistence

    func loadLayout() {
        guard fileManager.fileExists(atPath: layoutFilePath.path) else {
            print("[DEBUG][LockScreenSettingsManager] No saved layout found at \(layoutFilePath.path)")
            return
        }
        do {
            let data = try Data(contentsOf: layoutFilePath)
            let decoded = try JSONDecoder().decode(LockScreenLayout.self, from: data)
            self.layout = decoded
            print("[DEBUG][LockScreenSettingsManager] Loaded layout successfully. Stickers count: \(layout.stickers.count), bgType: \(layout.backgroundType)")
        } catch {
            print("[DEBUG][LockScreenSettingsManager] ERROR loading LockScreenLayout: \(error)")
        }
    }

    func saveLayout() {
        do {
            let data = try JSONEncoder().encode(layout)
            try data.write(to: layoutFilePath, options: .atomic)
            print("[DEBUG][LockScreenSettingsManager] Saved layout successfully. Stickers count: \(layout.stickers.count)")
        } catch {
            print("[DEBUG][LockScreenSettingsManager] ERROR saving LockScreenLayout: \(error)")
        }
    }

    // MARK: - Asset Import & Management

    /// 로컬 이미지 파일을 샌드박스 내부(CustomAssets)로 안전하게 복사
    func importImageToSandbox(_ originalURL: URL) -> String? {
        print("[DEBUG][LockScreenSettingsManager] importImageToSandbox starting for URL: \(originalURL.path)")
        createDirectoriesIfNeeded()

        let extensionName = originalURL.pathExtension.isEmpty ? "png" : originalURL.pathExtension
        let filename = "\(UUID().uuidString).\(extensionName)"
        let destinationURL = customAssetsDirectory.appendingPathComponent(filename)

        let isAccessing = originalURL.startAccessingSecurityScopedResource()
        print("[DEBUG][LockScreenSettingsManager] startAccessingSecurityScopedResource returned: \(isAccessing)")
        defer {
            if isAccessing {
                originalURL.stopAccessingSecurityScopedResource()
            }
        }

        do {
            // Data 바이너리 로드 및 write로 안전하게 복사 (Permission 에러 방지)
            let imageData = try Data(contentsOf: originalURL)
            try imageData.write(to: destinationURL, options: .atomic)
            print("[DEBUG][LockScreenSettingsManager] Image successfully written to sandbox: \(destinationURL.path) (size: \(imageData.count) bytes)")
            return destinationURL.path
        } catch {
            print("[DEBUG][LockScreenSettingsManager] ERROR writing image data to sandbox: \(error)")
            // Fallback for copyItem
            do {
                if fileManager.fileExists(atPath: destinationURL.path) {
                    try fileManager.removeItem(at: destinationURL)
                }
                try fileManager.copyItem(at: originalURL, to: destinationURL)
                print("[DEBUG][LockScreenSettingsManager] Fallback copyItem succeeded: \(destinationURL.path)")
                return destinationURL.path
            } catch let copyError {
                print("[DEBUG][LockScreenSettingsManager] ERROR fallback copyItem failed: \(copyError)")
                return nil
            }
        }
    }

    /// 상대 경로 또는 파일명을 수용하여 NSImage 불러오기
    func loadImage(from pathString: String) -> NSImage? {
        let url: URL
        if pathString.hasPrefix("/") {
            url = URL(fileURLWithPath: pathString)
        } else {
            url = customAssetsDirectory.appendingPathComponent(pathString)
        }
        let image = NSImage(contentsOf: url)
        print("[DEBUG][LockScreenSettingsManager] loadImage '\(pathString)' -> \(image != nil ? "SUCCESS (size: \(image?.size ?? .zero))" : "FAILED (nil)")")
        return image
    }

    // MARK: - Helper Actions

    /// 배경 이미지 변경
    func setCustomBackgroundImage(url: URL) {
        print("[DEBUG][LockScreenSettingsManager] setCustomBackgroundImage called for: \(url.path)")
        if let savedPath = importImageToSandbox(url) {
            objectWillChange.send()
            layout.backgroundImagePath = savedPath
            layout.backgroundType = .customImage
            saveLayout()
            print("[DEBUG][LockScreenSettingsManager] Background image set successfully to \(savedPath)")
        } else {
            print("[DEBUG][LockScreenSettingsManager] ERROR: setCustomBackgroundImage failed to import image.")
        }
    }

    /// 스티커 추가
    func addSticker(url: URL) {
        print("[DEBUG][LockScreenSettingsManager] addSticker called for: \(url.path)")
        if let savedPath = importImageToSandbox(url) {
            objectWillChange.send()
            let newItem = StickerItem(imagePath: savedPath, x: 0, y: 0, scale: 1.0, rotation: 0.0)
            layout.stickers.append(newItem)
            saveLayout()
            print("[DEBUG][LockScreenSettingsManager] Sticker added successfully. Total stickers: \(layout.stickers.count)")
        } else {
            print("[DEBUG][LockScreenSettingsManager] ERROR: addSticker failed to import image.")
        }
    }

    /// 스티커 삭제
    func removeSticker(id: UUID) {
        print("[DEBUG][LockScreenSettingsManager] removeSticker called for ID: \(id)")
        objectWillChange.send()
        layout.stickers.removeAll { $0.id == id }
        saveLayout()
    }

    /// 레이아웃 초기화
    func resetToDefault() {
        print("[DEBUG][LockScreenSettingsManager] resetToDefault called.")
        objectWillChange.send()
        layout = LockScreenLayout()
        saveLayout()
    }
}
