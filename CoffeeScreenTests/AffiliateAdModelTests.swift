import AppKit
import Lottie
import SwiftUI
import XCTest
@testable import CoffeeScreen

final class AffiliateAdModelTests: XCTestCase {

    func testDecodeLegacyAdItemPreservesCompatibility() throws {
        let json = """
        {
          "version": 1,
          "rotationIntervalSec": 60,
          "items": [
            {
              "id": "toss-ocarina-01",
              "tagline": "🎵 HOBBY & MUSIC",
              "title": "삼익 오카리나",
              "subtitle": "카메라로 QR 스캔",
              "shareUrl": "https://toss.im/_m/Hb4eUkQu",
              "qrUrl": "https://toss.im/_m/Hb4eUkQu",
              "imageUrl": "https://example.com/item.png",
              "disclosure": "제휴 안내"
            }
          ]
        }
        """

        let feed = try JSONDecoder().decode(AffiliateAdFeed.self, from: Data(json.utf8))
        XCTAssertEqual(feed.items.count, 1)
        let item = try XCTUnwrap(feed.items.first)
        XCTAssertEqual(item.targetQRString, "https://toss.im/_m/Hb4eUkQu")
        XCTAssertEqual(item.mediaFormat, .image)
        XCTAssertEqual(item.validImageURL?.absoluteString, "https://example.com/item.png")
        XCTAssertTrue(item.hasMedia)
        XCTAssertTrue(item.hasAnyContent)
    }

    func testDecodeAbstractedGreetingMessageItemWithRepoRelativeLottie() throws {
        let json = """
        {
          "version": 1,
          "rotationIntervalSec": 60,
          "items": [
            {
              "id": "greeting-coffee-01",
              "type": "message",
              "tagline": "☕️ COFFEE-SCREEN",
              "title": "사용해 주셔서 항상 감사합니다.",
              "subtitle": "오늘도 편안하고 안전한 작업 시간 되세요",
              "imageUrl": "banners/greeting.json"
            }
          ]
        }
        """

        let feed = try JSONDecoder().decode(AffiliateAdFeed.self, from: Data(json.utf8))
        let item = try XCTUnwrap(feed.items.first)
        XCTAssertNil(item.targetQRString)
        XCTAssertNil(item.trimmedDisclosure)
        XCTAssertEqual(item.mediaFormat, .lottie)
        XCTAssertEqual(
            item.validImageURL?.absoluteString,
            "https://raw.githubusercontent.com/Gorita/Coffee-Screen/main/banners/greeting.json"
        )
        XCTAssertTrue(item.hasMedia)
        XCTAssertTrue(item.hasAnyContent)
    }

    func testMediaFormatsAndFallbackIcons() throws {
        let gifJSON = """
        {"id": "gif-1", "title": "Hello", "imageUrl": "banners/wave.gif"}
        """
        let gifItem = try JSONDecoder().decode(AffiliateAdItem.self, from: Data(gifJSON.utf8))
        XCTAssertEqual(gifItem.mediaFormat, .gif)
        XCTAssertTrue(gifItem.hasMedia)

        let symbolJSON = """
        {"id": "sym-1", "title": "Notice", "sfSymbol": "megaphone.fill", "accentColor": "#FF9500"}
        """
        let symbolItem = try JSONDecoder().decode(AffiliateAdItem.self, from: Data(symbolJSON.utf8))
        XCTAssertNil(symbolItem.validImageURL)
        XCTAssertEqual(symbolItem.trimmedSFSymbol, "megaphone.fill")
        XCTAssertTrue(symbolItem.hasMedia)

        let emptyJSON = """
        {"id": "empty-1", "title": "   ", "imageUrl": ""}
        """
        let emptyItem = try JSONDecoder().decode(AffiliateAdItem.self, from: Data(emptyJSON.utf8))
        XCTAssertFalse(emptyItem.hasMedia)
        XCTAssertFalse(emptyItem.hasAnyContent)
    }

    func testEmptyFeedDecoding() throws {
        let json = """
        {"version": 1, "rotationIntervalSec": 60, "items": []}
        """
        let feed = try JSONDecoder().decode(AffiliateAdFeed.self, from: Data(json.utf8))
        XCTAssertTrue(feed.items.isEmpty)
    }

    func testGreetingLottieFileDecodesWithValidBoundsAndDuration() throws {
        let testFileURL = URL(fileURLWithPath: #filePath)
        let repoRoot = testFileURL.deletingLastPathComponent().deletingLastPathComponent()
        let lottieURL = repoRoot.appendingPathComponent("banners/greeting.json")

        let data = try Data(contentsOf: lottieURL)
        let animation = try JSONDecoder().decode(LottieAnimation.self, from: data)
        XCTAssertGreaterThan(animation.duration, 0)
        XCTAssertEqual(animation.bounds.width, 240)
        XCTAssertEqual(animation.bounds.height, 240)
    }

    @MainActor
    func testLottieContainerStaysWithin60x60BoundsInsideSwiftUI() throws {
        let testFileURL = URL(fileURLWithPath: #filePath)
        let repoRoot = testFileURL.deletingLastPathComponent().deletingLastPathComponent()
        let lottieURL = repoRoot.appendingPathComponent("banners/greeting.json")

        let itemJSON = """
        {
          "id": "greeting-coffee-01",
          "type": "message",
          "tagline": "☕️ COFFEE-SCREEN",
          "title": "사용해 주셔서 항상 감사합니다.",
          "subtitle": "오늘도 편안하고 안전한 작업 시간 되세요",
          "imageUrl": "\(lottieURL.absoluteString)"
        }
        """
        let item = try JSONDecoder().decode(AffiliateAdItem.self, from: Data(itemJSON.utf8))

        let cardView = HStack(spacing: 16) {
            RemoteBannerMediaView(item: item)
                .frame(width: 60, height: 60)
                .clipped()
            VStack(alignment: .leading, spacing: 3) {
                if let title = item.trimmedTitle {
                    Text(title)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(width: 420, height: 86)

        let hostingView = NSHostingView(rootView: cardView)
        hostingView.frame = CGRect(x: 0, y: 0, width: 480, height: 140)

        let window = NSWindow(
            contentRect: CGRect(x: 0, y: 0, width: 480, height: 140),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.contentView = hostingView
        hostingView.layoutSubtreeIfNeeded()
        RunLoop.current.run(until: Date().addingTimeInterval(0.3))
        hostingView.layoutSubtreeIfNeeded()

        func findLottieContainer(in view: NSView) -> LottieContainerNSView? {
            if let match = view as? LottieContainerNSView { return match }
            for sub in view.subviews {
                if let found = findLottieContainer(in: sub) { return found }
            }
            return nil
        }

        let container = try XCTUnwrap(findLottieContainer(in: hostingView))
        XCTAssertLessThanOrEqual(container.frame.width, 60.5)
        XCTAssertLessThanOrEqual(container.frame.height, 60.5)
        XCTAssertLessThanOrEqual(container.animationView.frame.width, 60.5)
        XCTAssertLessThanOrEqual(container.animationView.frame.height, 60.5)
    }
}
