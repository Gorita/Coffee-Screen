import SwiftUI

/// Apple Human Interface Guidelines (HIG) 공식 권장 표준 Liquid Glassmorphism 잠금화면 쉐어링크 뷰
struct ShieldAdGlassBarView: View {
    @ObservedObject var adManager = AffiliateAdManager.shared

    // 잠금 화면 진입 후 1초 뒤 스르륵 올라오도록 상태 제어
    @State private var isVisible: Bool = false
    @State private var delayWorkItem: DispatchWorkItem?

    var body: some View {
        let item = adManager.currentAd ?? AffiliateAdManager.defaultItem

        VStack(spacing: 8) {
            // 1. 메인 리퀴드 글래스모피즘 바 (Apple 공식 표준 Material API)
            HStack(spacing: 14) {
                // 상품 썸네일 (52x52 둥근 사각형)
                thumbnailView(for: item)
                    .frame(width: 52, height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.5)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)

                // 텍스트 정보 영역 (Apple HIG Semantic Vibrancy 계층 적용)
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.tagline)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color(red: 0.95, green: 0.72, blue: 0.30)) // 시스템 앰버/골드 틴트
                        .tracking(0.5)

                    Text(item.title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.primary) // 배경에 따라 자동 최적화되는 Apple Primary Vibrancy
                        .lineLimit(1)

                    Text(item.subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary) // Apple Secondary Vibrancy
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
                        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(width: 520, height: 72)
            // 🌟 Apple 공식 권장: Metal 가속 Material + Shape 직접 바인딩
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.40),
                                Color.white.opacity(0.12),
                                Color.white.opacity(0.04)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.5 // Apple 표준 0.5pt 헤어라인
                    )
            )
            .shadow(color: .black.opacity(0.20), radius: 20, x: 0, y: 8)

            // 2. 절제된 미니멀 공정위 문구 (Apple Tertiary Vibrancy 적용)
            if let disclosure = item.disclosure {
                Text(disclosure)
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
                    .tracking(-0.2)
            }
        }
        .offset(y: isVisible ? 0 : 80)
        .opacity(isVisible ? 1.0 : 0.0)
        .animation(.spring(response: 0.65, dampingFraction: 0.75), value: isVisible)
        .onAppear {
            scheduleAppearance()
        }
        .onDisappear {
            cancelAppearance()
        }
    }

    // MARK: - 1초 딜레이 스르륵(Slide-up) 스케줄링

    private func scheduleAppearance() {
        cancelAppearance()
        let item = DispatchWorkItem {
            self.isVisible = true
        }
        delayWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: item)
    }

    private func cancelAppearance() {
        delayWorkItem?.cancel()
        delayWorkItem = nil
        isVisible = false
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
