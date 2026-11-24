import SwiftUI

/// Apple Human Interface Guidelines (HIG) 공식 권장 표준 Liquid Glassmorphism 잠금화면 하단 배너/카드 뷰
struct ShieldAdGlassBarView: View {
    @ObservedObject var adManager = AffiliateAdManager.shared

    // 잠금 화면 진입 후 1초 뒤 스르륵 올라오도록 상태 제어
    @State private var isVisible: Bool = false
    @State private var delayWorkItem: DispatchWorkItem?

    var body: some View {
        if let item = adManager.currentAd {
            let hasQR = item.targetQRString != nil
            let cardWidth: CGFloat = hasQR ? 550 : 420

            VStack(spacing: 8) {
                // 1. 메인 리퀴드 글래스모피즘 바 (Apple 공식 표준 Material API)
                HStack(spacing: 16) {
                    // 좌측 미디어 슬롯 (Lottie / GIF / 정지 이미지 / SF Symbol / Emoji)
                    if item.hasMedia {
                        RemoteBannerMediaView(item: item)
                            .frame(width: 60, height: 60)
                            .clipped()
                    }

                    // 중앙 텍스트 정보 영역 (Apple HIG Semantic Vibrancy 계층 적용)
                    if item.trimmedTagline != nil || item.trimmedTitle != nil || item.trimmedSubtitle != nil {
                        VStack(alignment: .leading, spacing: 3) {
                            if let tagline = item.trimmedTagline {
                                Text(tagline)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(item.accentSwiftUIColor)
                                    .tracking(0.5)
                            }

                            if let title = item.trimmedTitle {
                                Text(title)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.primary)
                                    .lineLimit(item.trimmedSubtitle == nil ? 2 : 1)
                            }

                            if let subtitle = item.trimmedSubtitle {
                                Text(subtitle)
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        .frame(maxWidth: hasQR ? 330 : .infinity, alignment: .leading)
                    }

                    if hasQR {
                        Spacer(minLength: 0)
                    }

                    // 우측 QR코드 영역 (shareUrl 또는 qrUrl이 있을 때만 렌더링)
                    if let qrString = item.targetQRString,
                       let qrImage = adManager.generateQRCode(from: qrString, size: 256) {
                        Image(nsImage: qrImage)
                            .interpolation(.none)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(5)
                            .background(Color.white)
                            .frame(width: 68, height: 68)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(width: cardWidth, height: 86)
                // 🌟 Apple 공식 권장: Metal 가속 Material + Shape 직접 바인딩
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
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
                .shadow(color: .black.opacity(0.20), radius: 22, x: 0, y: 8)

                // 2. 선택적 하단 고지/메타 문구 (Apple Tertiary Vibrancy 적용)
                if let disclosure = item.trimmedDisclosure {
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
}
