import SwiftUI

/// macOS Sequoia / Sonoma 리퀴드 글래스모피즘 네이티브 잠금화면 뷰
/// 5K 레티나 무손실 칼선명도 + 실제 현재 시각 연동 + 네이티브 인증 기능 내장
struct NativeMacOSLockScreenView: View {
    @ObservedObject var viewModel: ShieldViewModel

    @State private var currentTime = Date()
    @FocusState private var isFieldFocused: Bool
    @State private var shakeOffset: CGFloat = 0

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // 1. 5K 레티나 시네마틱 선셋 & 오로라 배경 (화질 손실 0% 네이티브 그래디언트)
            backgroundGradient

            VStack(spacing: 0) {
                // 2. 상단: 대형 SF Pro 날짜 & 시계
                VStack(spacing: 6) {
                    Text(formattedDate)
                        .font(.system(size: 26, weight: .medium, design: .default))
                        .foregroundStyle(Color.white.opacity(0.92))
                        .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 4)

                    Text(formattedTime)
                        .font(.system(size: 110, weight: .ultraLight, design: .default))
                        .monospacedDigit()
                        .foregroundStyle(Color.white.opacity(0.96))
                        .shadow(color: .black.opacity(0.45), radius: 20, x: 0, y: 6)
                        .tracking(-2)
                }
                .padding(.top, 90)

                Spacer()

                // 3. 중앙: 로그인 유저 프로필 & 리퀴드 글래스 암호 입력바
                VStack(spacing: 16) {
                    // 원형 아바타
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 1.0, green: 0.60, blue: 0.62), Color(red: 1.0, green: 0.81, blue: 0.94)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 88, height: 88)
                            .overlay(
                                Circle()
                                    .strokeBorder(Color.white.opacity(0.35), lineWidth: 1.5)
                            )
                            .shadow(color: .black.opacity(0.35), radius: 18, x: 0, y: 8)

                        Text("☕️")
                            .font(.system(size: 44))
                    }

                    // 사용자 이름
                    Text(currentUserName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.white)
                        .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 2)

                    // 리퀴드 글래스 암호 입력바
                    HStack(spacing: 8) {
                        SecureField("암호", text: $viewModel.pinInput)
                            .textFieldStyle(.plain)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.white)
                            .multilineTextAlignment(.leading)
                            .focused($isFieldFocused)
                            .onSubmit {
                                submitUnlock()
                            }

                        Button(action: {
                            submitUnlock()
                        }) {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(viewModel.pinInput.isEmpty ? Color.white.opacity(0.3) : Color.white.opacity(0.9))
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.pinInput.isEmpty)
                    }
                    .padding(.horizontal, 16)
                    .frame(width: 200, height: 36)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.white.opacity(0.32), lineWidth: 0.75)
                    )
                    .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 4)
                    .offset(x: shakeOffset)

                    // 힌트 텍스트 & Touch ID 버튼
                    if let error = viewModel.authError {
                        Text(error)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color(red: 1.0, green: 0.45, blue: 0.45))
                            .shadow(color: .black.opacity(0.6), radius: 4, x: 0, y: 1)
                    } else if viewModel.isBiometricAvailable {
                        Button(action: {
                            viewModel.attemptTouchID()
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: "touchid")
                                    .font(.system(size: 12))
                                Text("Touch ID 또는 암호 입력")
                                    .font(.system(size: 11, weight: .regular))
                            }
                            .foregroundStyle(Color.white.opacity(0.85))
                            .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 1)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Text("암호 입력")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(Color.white.opacity(0.72))
                            .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 1)
                    }
                }
                .padding(.bottom, 150)
            }
        }
        .onAppear {
            NSApp.activate(ignoringOtherApps: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isFieldFocused = true
            }
            if viewModel.isBiometricAvailable {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    viewModel.attemptTouchID()
                }
            }
        }
        .onReceive(timer) { input in
            currentTime = input
        }
        .onChange(of: viewModel.authError) { error in
            if error != nil {
                triggerShake()
            }
        }
    }

    private func submitUnlock() {
        viewModel.attemptPINUnlock()
    }

    private func triggerShake() {
        withAnimation(.default.speed(2.5)) {
            shakeOffset = -12
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(.default.speed(2.5)) {
                shakeOffset = 12
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            withAnimation(.default.speed(2.5)) {
                shakeOffset = 0
            }
        }
    }

    // MARK: - Computed Properties

    private var currentUserName: String {
        NSFullUserName().isEmpty ? "Coffee Developer" : NSFullUserName()
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 EEEE"
        return formatter.string(from: currentTime)
    }

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: currentTime)
    }

    private var backgroundGradient: some View {
        ZStack {
            // 기본 베이스 다크 톤
            LinearGradient(
                colors: [
                    Color(red: 0.11, green: 0.06, blue: 0.18),
                    Color(red: 0.05, green: 0.11, blue: 0.23),
                    Color(red: 0.03, green: 0.16, blue: 0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // 상단 따뜻한 선셋 방사형 글로우
            RadialGradient(
                colors: [Color(red: 1.0, green: 0.55, blue: 0.32).opacity(0.42), Color.clear],
                center: .init(x: 0.5, y: 0.32),
                startRadius: 20,
                endRadius: 700
            )

            // 하단 딥 블루 오로라 글로우
            RadialGradient(
                colors: [Color(red: 0.25, green: 0.50, blue: 1.0).opacity(0.30), Color.clear],
                center: .init(x: 0.25, y: 0.80),
                startRadius: 50,
                endRadius: 800
            )
        }
    }
}
