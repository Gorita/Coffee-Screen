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

    private init() {
        self.currentAd = nil
        self.feedItems = []
        loadInitialFeed()
        fetchRemoteFeed()
    }

    /// 초기 로컬 번들 ads.json 로드
    private func loadInitialFeed() {
        if let bundleURL = Bundle.main.url(forResource: "ads", withExtension: "json"),
           let data = try? Data(contentsOf: bundleURL),
           let feed = try? JSONDecoder().decode(AffiliateAdFeed.self, from: data) {
            let validItems = feed.items.filter { $0.hasAnyContent }
            if !validItems.isEmpty {
                self.feedItems = validItems
                self.currentAd = validItems.first
                startRotationTimer(interval: feed.rotationIntervalSec ?? 60)
            }
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
                let validItems = feed.items.filter { $0.hasAnyContent }
                DispatchQueue.main.async {
                    if validItems.isEmpty {
                        // 원격에서 유효한 items가 비어 있으면 하단 카드를 즉시 끕니다.
                        self.feedItems = []
                        self.currentAd = nil
                        self.rotationTimer?.cancel()
                    } else {
                        self.feedItems = validItems
                        if self.currentAd == nil || !validItems.contains(where: { $0.id == self.currentAd?.id }) {
                            self.currentAd = validItems.first
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
        qrFilter.setValue("L", forKey: "inputCorrectionLevel") // Low error correction = 최대 크기 굵은 도트 격자

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
