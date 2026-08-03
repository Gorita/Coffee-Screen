import AppKit
import CoreImage
import Vision

/// 100% 순수 Apple Vision AI 딥러닝 신경망 기반 배경 제거 엔진
enum StickerBackgroundRemover {
    /// Apple Vision AI 신경망 모델만을 사용하여 사물 내부 내용물은 100% 원본 유지하고 외곽 배경만 투명화
    static func removeBackground(from image: NSImage) -> NSImage? {
        guard #available(macOS 13.0, *) else {
            print("[WARN][StickerBackgroundRemover] Vision AI requires macOS 13.0 or later.")
            return image
        }

        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }

        // 1. Apple Vision AI 인공지능 피사체 분리 요청
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        do {
            try handler.perform([request])
            guard let result = request.results?.first else {
                print("[WARN][StickerBackgroundRemover] No foreground subject detected by Vision AI.")
                return image
            }

            // 2. Vision AI 딥러닝 모델이 인정한 피사체 영역만 알파 추출
            let maskPixelBuffer = try result.generateMaskedImage(
                ofInstances: result.allInstances,
                from: handler,
                croppedToInstancesExtent: false
            )

            let ciImage = CIImage(cvPixelBuffer: maskPixelBuffer)
            let context = CIContext()
            guard let outputCGImage = context.createCGImage(ciImage, from: ciImage.extent) else {
                return image
            }

            let resultImage = NSImage(cgImage: outputCGImage, size: image.size)
            print("[DEBUG][StickerBackgroundRemover] 100% Pure Vision AI Background Removal Succeeded.")
            return resultImage
        } catch {
            print("[ERROR][StickerBackgroundRemover] Vision AI request failed: \(error.localizedDescription)")
            return image
        }
    }
}
