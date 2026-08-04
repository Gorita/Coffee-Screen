import AppKit
import SwiftUI

/// 움직이는 GIF 애니메이션 배경 렌더링 전용 NSViewRepresentable 뷰
struct AnimatedGIFView: NSViewRepresentable {
    let imagePath: String
    let contentMode: ImageContentMode

    func makeNSView(context: Context) -> NSImageView {
        let imageView = NSImageView()
        imageView.imageScaling = (contentMode == .fill) ? .scaleAxesIndependently : .scaleProportionallyUpOrDown
        imageView.animates = true
        imageView.canDrawSubviewsIntoLayer = true
        imageView.wantsLayer = true
        updateImage(imageView: imageView)
        return imageView
    }

    func updateNSView(_ nsView: NSImageView, context: Context) {
        nsView.imageScaling = (contentMode == .fill) ? .scaleAxesIndependently : .scaleProportionallyUpOrDown
        updateImage(imageView: nsView)
    }

    private func updateImage(imageView: NSImageView) {
        let fileURL: URL
        if imagePath.hasPrefix("/") {
            fileURL = URL(fileURLWithPath: imagePath)
        } else {
            let customDir = LockScreenSettingsManager.shared.customAssetsDirectory
            fileURL = customDir.appendingPathComponent(imagePath)
        }

        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }

        // 이전 파일과 다른 경우에만 이미지 재경신
        if imageView.tag != fileURL.path.hashValue {
            imageView.tag = fileURL.path.hashValue
            if let image = NSImage(contentsOf: fileURL) {
                imageView.image = image
                imageView.animates = true
            }
        }
    }
}
