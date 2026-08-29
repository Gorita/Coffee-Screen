import Foundation
import AppKit
import CoreImage.CIFilterBuiltins
import Combine

/// 잠금화면 쉐어링크 광고 관리자 (원격 JSON 페치 + 로컬 캐시 + 고해상도 QR 생성)
final class AffiliateAdManager: ObservableObject {
    static let shared = AffiliateAdManager()

    @Published var currentAd: AffiliateAdItem?
    @Published var isEnabled: Bool = true

    private var feedItems: [AffiliateAdItem] = []
    private var currentIndex: Int = 0
    private var rotationTimer: AnyCancellable?
    private let context = CIContext()
    private let qrFilter = CIFilter.qrCodeGenerator()

    // 원격 ads.json CDN 주소
    private let remoteFeedURL = URL(string: "https://raw.githubusercontent.com/Gorita/Coffee-Screen/main/ads.json")

    // 기본 추천 아이템 (네트워크/번들 로딩 전 항상 즉시 표시)
    static let defaultItem = AffiliateAdItem(
        id: "toss-tea-01",
        tagline: "☕ TEA SELECTION",
        title: "몽베스트 블랜딩 티 (녹차&홍차 40개입)",
        subtitle: "작업 중 산뜻한 티타임 • 모바일 카메라로 스캔",
        shareUrl: "https://toss.im/_m/h6KNKtZf",
        qrUrl: "https://app.appsflyer.com/id839333328?pid=toss_shopping_web&c=toss_shopping_web_qr&af_dp=supertoss%3A//tosspay/shopping/product%3Fid%3D10046715%26referrer%3Daffiliate%26k%3Db448cd31-1625-4101-ba1d-f85dd9509d0e&deep_link_value=supertoss%3A//tosspay/shopping/product%3Fid%3D10046715%26referrer%3Daffiliate%26k%3Db448cd31-1625-4101-ba1d-f85dd9509d0e&af_force_deeplink=true",
        imageUrl: "https://shopping.toss.im/live/product/302023/96dc4e09-3728-429d-b554-a89c5e77f79f.jpg",
        disclosure: "✱ 토스쇼핑 쉐어링크 파트너스 활동의 일환으로 수수료를 제공받을 수 있습니다."
    )

    private init() {
        self.currentAd = Self.defaultItem
        self.feedItems = [Self.defaultItem]
        loadInitialFeed()
        fetchRemoteFeed()
    }

    /// 초기 로컬 번들 ads.json 로드
    private func loadInitialFeed() {
        if let bundleURL = Bundle.main.url(forResource: "ads", withExtension: "json"),
           let data = try? Data(contentsOf: bundleURL),
           let feed = try? JSONDecoder().decode(AffiliateAdFeed.self, from: data),
           !feed.items.isEmpty {
            self.feedItems = feed.items
            self.currentAd = feed.items.first
            startRotationTimer(interval: feed.rotationIntervalSec ?? 60)
        }
    }

    /// 원격 GitHub ads.json 비동기 업데이트
    func fetchRemoteFeed() {
        guard let url = remoteFeedURL else { return }

        var request = URLRequest(url: url)
        request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringLocalCacheData
        request.timeoutInterval = 10

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let self = self, let data = data, error == nil else { return }
            do {
                let feed = try JSONDecoder().decode(AffiliateAdFeed.self, from: data)
                if !feed.items.isEmpty {
                    DispatchQueue.main.async {
                        self.feedItems = feed.items
                        if self.currentAd == nil || !feed.items.contains(where: { $0.id == self.currentAd?.id }) {
                            self.currentAd = feed.items.first
                        }
                        self.startRotationTimer(interval: feed.rotationIntervalSec ?? 60)
                    }
                }
            } catch {
                // 원격 파싱 실패 시 로컬 캐시 유지
            }
        }.resume()
    }

    /// 다음 광고 아이템으로 로테이션
    func rotateToNext() {
        guard !feedItems.isEmpty else { return }
        currentIndex = (currentIndex + 1) % feedItems.count
        currentAd = feedItems[currentIndex]
    }

    private func startRotationTimer(interval: Int) {
        rotationTimer?.cancel()
        guard feedItems.count > 1 else { return }
        rotationTimer = Timer.publish(every: TimeInterval(interval), on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.rotateToNext()
            }
    }

    // MARK: - CoreImage 기반 고해상도 QR 생성기

    /// 주어진 URL 문자열로부터 깔끔한 고화질 NSImage QR코드를 생성합니다.
    func generateQRCode(from string: String, size: CGFloat = 120) -> NSImage? {
        guard let data = string.data(using: .utf8) else { return nil }

        qrFilter.setValue(data, forKey: "inputMessage")
        qrFilter.setValue("M", forKey: "inputCorrectionLevel") // Medium error correction

        guard let outputImage = qrFilter.outputImage else { return nil }

        // CoreImage 선명한 스케일링
        let scaleX = size / outputImage.extent.size.width
        let scaleY = size / outputImage.extent.size.height
        let transformedImage = outputImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        guard let cgImage = context.createCGImage(transformedImage, from: transformedImage.extent) else {
            return nil
        }

        return NSImage(cgImage: cgImage, size: NSSize(width: size, height: size))
    }
}
