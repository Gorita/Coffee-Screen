import Foundation
import SwiftUI

/// 하단 배너/카드 미디어 포맷
enum BannerMediaFormat: Equatable {
    case lottie
    case gif
    case image
}

/// 하단 배너/메시지/제휴 카드 피드 데이터 모델
struct AffiliateAdFeed: Codable {
    let version: Int
    let rotationIntervalSec: Int?
    let items: [AffiliateAdItem]
}

/// 개별 하단 배너/메시지/제휴 카드 아이템 모델
struct AffiliateAdItem: Identifiable, Codable, Equatable {
    let id: String
    let type: String?
    let tagline: String?
    let title: String?
    let subtitle: String?
    let shareUrl: String?
    let qrUrl: String?
    let imageUrl: String?
    let sfSymbol: String?
    let emoji: String?
    let accentColor: String?
    let disclosure: String?

    static let repoRawBaseURL = "https://raw.githubusercontent.com/Gorita/Coffee-Screen/main/"

    private static func trimmed(_ value: String?) -> String? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
            return nil
        }
        return value
    }

    var trimmedTagline: String? { Self.trimmed(tagline) }
    var trimmedTitle: String? { Self.trimmed(title) }
    var trimmedSubtitle: String? { Self.trimmed(subtitle) }
    var trimmedDisclosure: String? { Self.trimmed(disclosure) }
    var trimmedSFSymbol: String? { Self.trimmed(sfSymbol) }
    var trimmedEmoji: String? { Self.trimmed(emoji) }

    /// QR코드 생성에 사용할 대상 URL 문자열 (값이 있을 때만 QR 표시)
    var targetQRString: String? {
        Self.trimmed(qrUrl) ?? Self.trimmed(shareUrl)
    }

    var validShareURL: URL? {
        guard let share = Self.trimmed(shareUrl) else { return nil }
        return URL(string: share)
    }

    /// 외부 URL 또는 레포 상대경로(예: "banners/greeting.json")를 URL로 변환
    var validImageURL: URL? {
        guard let raw = Self.trimmed(imageUrl) else { return nil }
        let lower = raw.lowercased()
        if lower.hasPrefix("http://") || lower.hasPrefix("https://") || lower.hasPrefix("file://") {
            return URL(string: raw)
        }
        let relativePath = raw.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard !relativePath.isEmpty else { return nil }
        return URL(string: Self.repoRawBaseURL + relativePath)
    }

    var mediaFormat: BannerMediaFormat {
        guard let ext = validImageURL?.pathExtension.lowercased() else {
            return .image
        }
        switch ext {
        case "json", "lottie":
            return .lottie
        case "gif":
            return .gif
        default:
            return .image
        }
    }

    var hasMedia: Bool {
        validImageURL != nil || trimmedSFSymbol != nil || trimmedEmoji != nil
    }

    var hasAnyContent: Bool {
        hasMedia || trimmedTagline != nil || trimmedTitle != nil || trimmedSubtitle != nil || targetQRString != nil
    }

    var accentSwiftUIColor: Color {
        if let hex = Self.trimmed(accentColor), let parsed = Color(hex: hex) {
            return parsed
        }
        return Color(red: 0.95, green: 0.72, blue: 0.30)
    }
}

typealias ShieldBannerFeed = AffiliateAdFeed
typealias ShieldBannerItem = AffiliateAdItem
