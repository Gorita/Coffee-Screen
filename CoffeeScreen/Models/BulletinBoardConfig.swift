import Foundation
import SwiftUI

// MARK: - 알림 표시 스타일

enum BulletinDisplayStyle: String, Codable, CaseIterable, Identifiable {
    case alert      = "alert"      // 우상단 슬라이드인 카드
    case terminal   = "terminal"   // 다크 터미널 창 로그
    case pixelText  = "pixelText"  // 픽셀 폰트 텍스트 오버레이

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .alert:     return "알림 카드 (Alert)"
        case .terminal:  return "터미널 창 (Terminal)"
        case .pixelText: return "픽셀 텍스트 (Pixel Text)"
        }
    }

    var iconName: String {
        switch self {
        case .alert:     return "bell.badge.fill"
        case .terminal:  return "terminal.fill"
        case .pixelText: return "textformat.alt"
        }
    }
}

// MARK: - 메시지 레벨

enum BulletinMessageLevel: String, Codable {
    case info    = "info"
    case success = "success"
    case warning = "warning"
    case error   = "error"

    var color: Color {
        switch self {
        case .info:    return Color(hex: "#3B82F6") ?? .blue
        case .success: return Color(hex: "#22C55E") ?? .green
        case .warning: return Color(hex: "#F59E0B") ?? .yellow
        case .error:   return Color(hex: "#EF4444") ?? .red
        }
    }

    var iconName: String {
        switch self {
        case .info:    return "info.circle.fill"
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error:   return "xmark.circle.fill"
        }
    }
}

// MARK: - 런타임 메시지 (비저장, 메모리 전용)

struct BulletinMessage: Identifiable, Equatable {
    let id: UUID
    let text: String
    let level: BulletinMessageLevel
    let timestamp: Date

    init(text: String, level: BulletinMessageLevel = .info) {
        self.id        = UUID()
        self.text      = text
        self.level     = level
        self.timestamp = Date()
    }
}

// MARK: - 알림판 설정 (저장됨)

struct BulletinBoardConfig: Codable, Equatable {
    /// 소켓 서버 활성화 여부
    var isEnabled: Bool = false

    /// Unix Domain Socket 경로
    var socketPath: String = "/tmp/coffee-screen.sock"

    /// 표시 스타일
    var displayStyle: BulletinDisplayStyle = .alert

    /// 최대 표시 메시지 수
    var maxMessages: Int = 5

    /// 자동 사라짐 시간 (초, 0 = 자동 사라짐 없음)
    var autoDismissDuration: Double = 8.0

    /// 픽셀 텍스트 스타일 글자 색상
    var fontColorHex: String = "#FFFFFF"

    /// 픽셀 텍스트 글자 크기
    var fontSize: CGFloat = 16

    /// 픽셀 텍스트 X 위치
    var positionX: CGFloat = 0

    /// 픽셀 텍스트 Y 위치 (양수 = 아래)
    var positionY: CGFloat = 200

    var fontColor: Color {
        Color(hex: fontColorHex) ?? .white
    }
}
