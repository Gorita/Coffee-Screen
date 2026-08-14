import SwiftUI
import AppKit

struct SupportCoffeeModalView: View {
    @Binding var isPresented: Bool
    private let pixelFont = "Silkscreen-Regular"
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with larger font
            HStack {
                Text("☕")
                    .font(.system(size: 24))
                Text("BUY ME A COFFEE")
                    .font(.custom(pixelFont, size: 18))
                    .foregroundColor(.coffeeDark)
                Spacer()
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.gray.opacity(0.8))
                }
                .buttonStyle(.plain)
            }
            
            // Subtitle
            Text("Coffee-Screen 개발자에게 커피 한 잔을 후원해주세요!\n스마트폰 카메라로 아래 QR을 비추면 바로 송금됩니다.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            
            // Halftone Animated QR Image Wrapper (100% Full Aspect Fit)
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
                    .frame(width: 210, height: 210)
                
                if let qrPath = Bundle.main.path(forResource: "qr_kakaopay_support", ofType: "gif") ?? getFallbackQRPath() {
                    AnimatedGIFView(imagePath: qrPath, contentMode: .fit)
                        .frame(width: 196, height: 196)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    ProgressView()
                        .frame(width: 196, height: 196)
                }
            }
            .padding(.vertical, 4)
            
            Text("화면 바깥을 누르면 닫힙니다")
                .font(.system(size: 10))
                .foregroundColor(.secondary.opacity(0.7))
        }
        .padding(24)
        .frame(width: 290)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(nsColor: .windowBackgroundColor))
                .shadow(color: Color.black.opacity(0.35), radius: 20, x: 0, y: 10)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
        // Prevent background taps inside modal from dismissing
        .onTapGesture { }
    }
    
    private func getFallbackQRPath() -> String? {
        let fallback = "/Users/mireuk/GeminiCli/Coffee-Screen/CoffeeScreen/Resources/qr_kakaopay_support.gif"
        return FileManager.default.fileExists(atPath: fallback) ? fallback : nil
    }
}
