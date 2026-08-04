import Foundation
import SwiftUI

/// 락스크린 배경 타입
enum BackgroundType: String, Codable, CaseIterable, Identifiable {
    case solidColor
    case customImage

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .solidColor:
            return String(localized: "Background.SolidColor", defaultValue: "Solid Color")
        case .customImage:
            return String(localized: "Background.CustomImage", defaultValue: "Custom Image")
        }
    }
}

/// 이미지 배경 맞춤 모드 (Fill / Fit)
enum ImageContentMode: String, Codable, CaseIterable, Identifiable {
    case fill
    case fit

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fill:
            return String(localized: "ContentMode.Fill", defaultValue: "Fill Screen")
        case .fit:
            return String(localized: "ContentMode.Fit", defaultValue: "Fit Screen")
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

/// 상단 헤더 아이콘 스타일
enum UnlockHeaderIcon: String, Codable, CaseIterable, Identifiable {
    case none
    case customImage
    case lock
    case coffee
    case shield
    case key

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none: return String(localized: "HeaderIcon.None", defaultValue: "None (Hidden)")
        case .customImage: return String(localized: "HeaderIcon.CustomImage", defaultValue: "Custom Image")
        case .lock: return String(localized: "HeaderIcon.Lock", defaultValue: "Lock Icon")
        case .coffee: return String(localized: "HeaderIcon.Coffee", defaultValue: "Coffee Cup")
        case .shield: return String(localized: "HeaderIcon.Shield", defaultValue: "Shield")
        case .key: return String(localized: "HeaderIcon.Key", defaultValue: "Key")
        }
    }

    var systemIconName: String? {
        switch self {
        case .lock: return "lock.fill"
        case .coffee: return "cup.and.saucer.fill"
        case .shield: return "shield.checkerboard"
        case .key: return "key.fill"
        default: return nil
        }
    }
}

/// 지문(Touch ID) 심볼 스타일
enum TouchIDIconStyle: String, Codable, CaseIterable, Identifiable {
    case touchID
    case faceID
    case keyhole

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .touchID: return String(localized: "TouchIDStyle.TouchID", defaultValue: "Touch ID")
        case .faceID: return String(localized: "TouchIDStyle.FaceID", defaultValue: "Face ID")
        case .keyhole: return String(localized: "TouchIDStyle.Keyhole", defaultValue: "Keyhole")
        }
    }

    var systemIconName: String {
        switch self {
        case .touchID: return "touchid"
        case .faceID: return "faceid"
        case .keyhole: return "key.horizontal.fill"
        }
    }
}

/// 버튼 외형 스타일 타입 (Solid Filled, Outlined, Glassmorphic)
enum ButtonStyleType: String, Codable, CaseIterable, Identifiable {
    case solid
    case outlined
    case glass

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .solid: return String(localized: "ButtonStyle.Solid", defaultValue: "Solid Filled")
        case .outlined: return String(localized: "ButtonStyle.Outlined", defaultValue: "Outlined Border")
        case .glass: return String(localized: "ButtonStyle.Glass", defaultValue: "Glassmorphic")
        }
    }
}

/// PIN 키패드 버튼 스타일
enum PINButtonStyle: String, Codable, CaseIterable, Identifiable {
    case pixel
    case circle
    case glass

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .pixel: return String(localized: "PINStyle.Pixel", defaultValue: "Pixel Dot")
        case .circle: return String(localized: "PINStyle.Circle", defaultValue: "Minimal Circle")
        case .glass: return String(localized: "PINStyle.Glass", defaultValue: "Glassmorphic")
        }
    }
}

/// PIN 입력 마스크 문자
enum PINMaskSymbol: String, Codable, CaseIterable, Identifiable {
    case dot = "●"
    case star = "★"
    case coffee = "☕"
    case lock = "🔒"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .dot: return "Dot (●)"
        case .star: return "Star (★)"
        case .coffee: return "Coffee (☕)"
        case .lock: return "Lock (🔒)"
        }
    }
}

/// 스티커 테두리 / 프레임 스타일
enum StickerStyle: String, Codable, CaseIterable, Identifiable {
    case whiteBorder
    case clean
    case polaroid

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .whiteBorder:
            return String(localized: "StickerStyle.WhiteBorder", defaultValue: "White Border")
        case .clean:
            return String(localized: "StickerStyle.Clean", defaultValue: "Clean Image")
        case .polaroid:
            return String(localized: "StickerStyle.Polaroid", defaultValue: "Polaroid Frame")
        }
    }
}

/// 인증 창 위치 및 카드 모양 설정
struct UnlockWindowConfig: Codable, Equatable {
    var style: UnlockWindowStyle = .none
    var xOffset: CGFloat = 0
    var yOffset: CGFloat = 0
    var opacity: Double = 0.45

    // 상단 헤더 아이콘 커스텀
    var headerIcon: UnlockHeaderIcon = .lock
    var headerCustomImagePath: String? = nil
    var headerIconColorHex: String = "#FFFFFF"

    // 지문 인증 커스텀
    var touchIDStyle: TouchIDIconStyle = .touchID
    var isTouchIDVisible: Bool = true
    var touchIDButtonColorHex: String = "#007AFF"
    var touchIDButtonWidth: CGFloat = 160
    var touchIDButtonStyle: ButtonStyleType = .solid
    var touchIDButtonText: String = "Unlock"
    var touchIDButtonOpacity: Double = 1.0

    // PIN 키패드 및 마스크 커스텀
    var pinButtonStyle: PINButtonStyle = .pixel
    var pinMaskSymbol: PINMaskSymbol = .dot
    var pinInputBoxWidth: CGFloat = 200
    var pinInputBoxOpacity: Double = 0.4
    var pinInputBoxColorHex: String = "#000000"
    var pinButtonWidth: CGFloat = 160
    var pinConfirmButtonText: String = "Confirm"
    var pinConfirmButtonColorHex: String = "#34C759"
    var pinConfirmButtonOpacity: Double = 1.0

    // 인증 모드 전환 버튼 (Use PIN / Use Touch ID) 커스텀
    var isModeSwitchButtonVisible: Bool = true
    var usePINText: String = "Use PIN"
    var useTouchIDText: String = "Use Touch ID"
    var modeSwitchFontSize: CGFloat = 10
    var modeSwitchColorHex: String = "#FFFFFF"
    var modeSwitchOpacity: Double = 0.7

    // Mac 종료 버튼 노출 여부
    var isShutdownButtonVisible: Bool = true

    // Unlock Box 내부 타이틀 & 안내 메시지 커스텀
    var titleText: String = "CoffeeScreen"
    var isTitleVisible: Bool = true
    var titleFontSize: CGFloat = 24
    var titleColorHex: String = "#FFFFFF"

    var subtextText: String = "Authenticate to unlock"
    var isSubtextVisible: Bool = true
    var subtextFontSize: CGFloat = 12
    var subtextColorHex: String = "#B0B0B0"

    var headerIconColor: Color {
        Color(hex: headerIconColorHex) ?? Color.yellow
    }

    var touchIDButtonColor: Color {
        Color(hex: touchIDButtonColorHex) ?? Color.blue
    }

    var pinConfirmButtonColor: Color {
        Color(hex: pinConfirmButtonColorHex) ?? Color.green
    }

    var pinInputBoxColor: Color {
        Color(hex: pinInputBoxColorHex) ?? Color.black
    }

    var modeSwitchColor: Color {
        Color(hex: modeSwitchColorHex) ?? Color.white
    }

    var titleColor: Color {
        Color(hex: titleColorHex) ?? .white
    }

    var subtextColor: Color {
        Color(hex: subtextColorHex) ?? Color.white.opacity(0.7)
    }
}

/// 락스크린에 추가 배치되는 스티커/이미지 아이템 (커스텀 이미지 및 프리셋 아이콘 겸용)
struct StickerItem: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    /// 앱 샌드박스 내부 저장 이미지 파일 경로 (절대경로 또는 상대 파일명)
    var imagePath: String? = nil
    /// 프리셋 SF Symbol 아이콘 이름
    var systemIconName: String? = nil
    /// 스티커 표시 이름
    var name: String = "Sticker"
    /// X 좌표
    var x: CGFloat = 0
    /// Y 좌표
    var y: CGFloat = 0
    /// 스케일 (0.2 ~ 3.0)
    var scale: CGFloat = 1.0
    /// 회전 각도 (degrees)
    var rotation: Double = 0.0
    /// 스티커 테두리/프레임 스타일
    var style: StickerStyle = .whiteBorder
    /// AI 자동 배경 제거(누끼) 적용 여부
    var isBackgroundRemoved: Bool = false
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
    var backgroundType: BackgroundType = .solidColor
    var backgroundColorHex: String = "#000000"
    var backgroundImagePath: String?

    /// 최근 사용/등록된 커스텀 이미지 히스토리 경로들 (최대 6개)
    var recentImagePaths: [String] = []

    /// 배경 이미지 Crop / Alignment 설정
    var imageContentMode: ImageContentMode = .fill
    var imageScale: CGFloat = 1.0
    var imageOffsetX: CGFloat = 0
    var imageOffsetY: CGFloat = 0

    var stickers: [StickerItem] = []

    var unlockWindowConfig: UnlockWindowConfig = UnlockWindowConfig()

    var clockConfig: WidgetConfig = WidgetConfig(
        isEnabled: false,
        x: 0,
        y: -160,
        fontColorHex: "#FFFFFF",
        fontSize: 48
    )
    
    var infoMessageConfig: WidgetConfig = WidgetConfig(
        isEnabled: false,
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
