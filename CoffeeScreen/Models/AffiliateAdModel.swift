import Foundation

/// 제휴 쉐어링크 광고 피드 데이터 모델
struct AffiliateAdFeed: Codable {
    let version: Int
    let rotationIntervalSec: Int?
    let items: [AffiliateAdItem]
}

/// 개별 제휴 광고 아이템 모델
struct AffiliateAdItem: Identifiable, Codable, Equatable {
    let id: String
    let tagline: String
    let title: String
    let subtitle: String
    let shareUrl: String
    let imageUrl: String
    let disclosure: String?

    var validShareURL: URL? {
        URL(string: shareUrl)
    }

    var validImageURL: URL? {
        URL(string: imageUrl)
    }
}
