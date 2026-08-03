import Foundation
import SwiftUI

/// 락스크린 배경 타입
enum BackgroundType: String, Codable, CaseIterable, Identifiable {
    case solidColor
    case customImage
    case vintageGrid
    case pixelArt

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .solidColor:
            return String(localized: "Background.SolidColor", defaultValue: "Solid Color")
        case .customImage:
            return String(localized: "Background.CustomImage", defaultValue: "Custom Image")
        case .vintageGrid:
            return String(localized: "Background.VintageGrid", defaultValue: "Vintage Grid")
        case .pixelArt:
            return String(localized: "Background.PixelArt", defaultValue: "Pixel Art")
        }
    }
}

/// 인증 창(Unlock Window) 박스 스타일
enum UnlockWindowStyle: String, Codable, CaseIterable, Identifiable {
    case glassmorphic
    case solidBlack
    case none

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .glassmorphic:
            return String(localized: "UnlockStyle.Glassmorphic", defaultValue: "Glassmorphic Box")
        case .solidBlack:
            return String(localized: "UnlockStyle.SolidBlack", defaultValue: "Solid Black Box")
        case .none:
            return String(localized: "UnlockStyle.None", defaultValue: "None (Minimal)")
        }
    }
}

/// 인증 창 위치 및 카드 모양 설정
struct UnlockWindowConfig: Codable, Equatable {
    var style: UnlockWindowStyle = .glassmorphic
    var xOffset: CGFloat = 0
    var yOffset: CGFloat = 0
    var opacity: Double = 0.45
}

/// 락스크린에 추가 배치되는 스티커/이미지 아이템
struct StickerItem: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    /// 앱 샌드박스 내부 저장 이미지 파일 경로 (절대경로 또는 상대 파일명)
    var imagePath: String
    /// X 좌표
    var x: CGFloat = 0
    /// Y 좌표
    var y: CGFloat = 0
    /// 스케일 (0.2 ~ 3.0)
    var scale: CGFloat = 1.0
    /// 회전 각도 (degrees)
    var rotation: Double = 0.0
}

/// 락스크린 위젯 설정 (시계, 문구 등)
struct WidgetConfig: Codable, Equatable {
    var isEnabled: Bool = true
    var text: String? = nil
    var x: CGFloat = 0
    var y: CGFloat = 0
    var fontColorHex: String = "#FFFFFF"
    var fontSize: CGFloat = 32

    var fontColor: Color {
        Color(hex: fontColorHex) ?? .white
    }
}

/// 락스크린 전체 설정을 담는 데이터 구조체
struct LockScreenLayout: Codable, Equatable {
    var backgroundType: BackgroundType = .vintageGrid
    var backgroundColorHex: String = "#000000"
    var backgroundImagePath: String?
    var stickers: [StickerItem] = []

    var unlockWindowConfig: UnlockWindowConfig = UnlockWindowConfig()

    var clockConfig: WidgetConfig = WidgetConfig(
        isEnabled: true,
        x: 0,
        y: -160,
        fontColorHex: "#FFFFFF",
        fontSize: 48
    )
    
    var infoMessageConfig: WidgetConfig = WidgetConfig(
        isEnabled: true,
        x: 0,
        y: -100,
        fontColorHex: "#E0E0E0",
        fontSize: 14
    )

    var backgroundColor: Color {
        Color(hex: backgroundColorHex) ?? .black
    }
}

// MARK: - Color Hex Extension Helper
extension Color {
    init?(hex: String) {
        let r, g, b, a: Double
        let start = hex.hasPrefix("#") ? hex.index(hex.startIndex, offsetBy: 1) : hex.startIndex
        let hexColor = String(hex[start...])

        let scanner = Scanner(string: hexColor)
        var hexNumber: UInt64 = 0

        if scanner.scanHexInt64(&hexNumber) {
            if hexColor.count == 8 {
                r = Double((hexNumber & 0xff000000) >> 24) / 255
                g = Double((hexNumber & 0x00ff0000) >> 16) / 255
                b = Double((hexNumber & 0x0000ff00) >> 8) / 255
                a = Double(hexNumber & 0x000000ff) / 255
            } else if hexColor.count == 6 {
                r = Double((hexNumber & 0xff0000) >> 16) / 255
                g = Double((hexNumber & 0x00ff00) >> 8) / 255
                b = Double(hexNumber & 0x0000ff) / 255
                a = 1.0
            } else {
                return nil
            }

            self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
            return
        }

        return nil
    }

    func toHex() -> String {
        guard let nsColor = NSColor(self).usingColorSpace(.sRGB) else {
            return "#000000"
        }
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        nsColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02lX%02lX%02lX", lroundf(Float(r) * 255), lroundf(Float(g) * 255), lroundf(Float(b) * 255))
    }
}
