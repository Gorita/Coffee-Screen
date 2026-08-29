import SwiftUI

/// macOS Now-Playing 스타일 Liquid Glassmorphism 잠금화면 쉐어링크 뷰
struct ShieldAdGlassBarView: View {
    @ObservedObject var adManager = AffiliateAdManager.shared

    var body: some View {
        if let item = adManager.currentAd, adManager.isEnabled {
            VStack(spacing: 8) {
                // 1. 메인 글래스모피즘 바
                HStack(spacing: 14) {
                    // 상품 썸네일 (52x52 둥근 사각형)
                    thumbnailView(for: item)
                        .frame(width: 52, height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)

                    // 텍스트 정보 영역
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.tagline)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color(red: 0.90, green: 0.66, blue: 0.24)) // 웜 골드
                            .tracking(0.5)

                        Text(item.title)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white)
                            .lineLimit(1)

                        Text(item.subtitle)
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.6))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: 320, alignment: .leading)

                    Spacer(minLength: 0)

                    // QR코드 영역 (글래스 인셋 스타일)
                    if let qrImage = adManager.generateQRCode(from: item.shareUrl, size: 104) {
                        Image(nsImage: qrImage)
                            .interpolation(.none)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(4)
                            .background(Color.white)
                            .frame(width: 52, height: 52)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 2)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(width: 520, height: 72)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color(red: 0.10, green: 0.11, blue: 0.14).opacity(0.65))
                        .background(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.5), radius: 24, x: 0, y: 12)

                // 2. 절제된 미니멀 공정위 문구 (화면 최하단 은은한 텍스트)
                if let disclosure = item.disclosure {
                    Text(disclosure)
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.35))
                        .tracking(-0.2)
                }
            }
            .transition(.opacity.combined(with: .move(edge: .bottom)))
            .animation(.easeInOut(duration: 0.4), value: item.id)
        }
    }

    @ViewBuilder
    private func thumbnailView(for item: AffiliateAdItem) -> some View {
        if let url = item.validImageURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                        .overlay(
                            ProgressView()
                                .scaleEffect(0.6)
                        )
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    fallbackThumbnail
                @unknown default:
                    fallbackThumbnail
                }
            }
        } else {
            fallbackThumbnail
        }
    }

    private var fallbackThumbnail: some View {
        Rectangle()
            .fill(Color(red: 0.15, green: 0.17, blue: 0.22))
            .overlay(
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color(red: 0.90, green: 0.66, blue: 0.24))
            )
    }
}
