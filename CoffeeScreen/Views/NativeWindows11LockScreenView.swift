import SwiftUI

/// Windows 11 Fluent Bloom 네이티브 잠금화면 뷰
/// 5K 레티나 무손실 칼선명도 + 실제 현재 시각 연동 + 윈도우 11 Fluent Design 인풋 내장
struct NativeWindows11LockScreenView: View {
    @ObservedObject var viewModel: ShieldViewModel

    @State private var currentTime = Date()
    @FocusState private var isFieldFocused: Bool
    @State private var shakeOffset: CGFloat = 0

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // 1. 윈도우 11 시그니처 딥 블루 블룸(Bloom) 벡터 배경
            windowsBloomGradient

            VStack(spacing: 0) {
                // 2. 상단: 윈도우 11 시계 & 날짜
                VStack(spacing: 6) {
                    Text(formattedTime)
                        .font(.system(size: 115, weight: .semibold, design: .default))
                        .monospacedDigit()
                        .foregroundStyle(Color.white)
                        .shadow(color: .black.opacity(0.55), radius: 18, x: 0, y: 6)
                        .tracking(-2)

                    Text(formattedDate)
                        .font(.system(size: 24, weight: .regular, design: .default))
                        .foregroundStyle(Color.white.opacity(0.95))
                        .shadow(color: .black.opacity(0.4), radius: 10, x: 0, y: 3)
                }
                .padding(.top, 100)

                Spacer()

                // 3. 중앙: Windows 11 유저 로그인 카드
                VStack(spacing: 16) {
                    // 유저 실루엣 아바타
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.14))
                            .background(.ultraThinMaterial, in: Circle())
                            .frame(width: 96, height: 96)
                            .overlay(
                                Circle()
                                    .strokeBorder(Color.white.opacity(0.40), lineWidth: 2)
                            )
                            .shadow(color: .black.opacity(0.35), radius: 16, x: 0, y: 6)

                        Image(systemName: "person.fill")
                            .font(.system(size: 46))
                            .foregroundStyle(Color.white.opacity(0.95))
                    }

                    // 계정명
                    Text(currentUserName)
                        .font(.system(size: 22, weight: .semibold, design: .default))
                        .foregroundStyle(Color.white)
                        .shadow(color: .black.opacity(0.6), radius: 8, x: 0, y: 2)

                    // Windows 11 PIN 입력 박스
                    HStack(spacing: 10) {
                        SecureField("PIN", text: $viewModel.pinInput)
                            .textFieldStyle(.plain)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color.white)
                            .multilineTextAlignment(.leading)
                            .focused($isFieldFocused)
                            .onSubmit {
                                submitUnlock()
                            }

                        Button(action: {
                            submitUnlock()
                        }) {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(Color(red: 0.38, green: 0.80, blue: 1.0))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 14)
                    .frame(width: 260, height: 38)
                    .background(Color(red: 0.08, green: 0.09, blue: 0.12).opacity(0.85))
                    .overlay(
                        VStack {
                            Spacer()
                            Rectangle()
                                .fill(Color(red: 0.38, green: 0.80, blue: 1.0))
                                .frame(height: 2)
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(Color.white.opacity(0.20), lineWidth: 0.75)
                    )
                    .shadow(color: .black.opacity(0.35), radius: 12, x: 0, y: 4)
                    .offset(x: shakeOffset)

                    // 에러 메시지
                    if let error = viewModel.authError {
                        Text(error)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color(red: 1.0, green: 0.45, blue: 0.45))
                            .shadow(color: .black.opacity(0.6), radius: 4, x: 0, y: 1)
                    }

                    if viewModel.isBiometricAvailable {
                        Button(action: {
                            viewModel.attemptTouchID()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "touchid")
                                    .font(.system(size: 14))
                                Text("지문으로 로그인")
                                    .font(.system(size: 12))
                            }
                            .foregroundStyle(Color(red: 0.38, green: 0.80, blue: 1.0))
                            .padding(.top, 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.bottom, 160)
            }

            // 4. 우측 하단 Windows 시스템 트레이 아이콘
            VStack {
                Spacer()
                HStack(spacing: 20) {
                    Spacer()
                    Image(systemName: "wifi")
                    Image(systemName: "accessibility")
                    Image(systemName: "power")
                }
                .font(.system(size: 18))
                .foregroundStyle(Color.white.opacity(0.85))
                .shadow(color: .black.opacity(0.5), radius: 6, x: 0, y: 2)
                .padding(.trailing, 40)
                .padding(.bottom, 32)
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
        NSFullUserName().isEmpty ? "Administrator" : NSFullUserName()
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

    private var windowsBloomGradient: some View {
        ZStack {
            // 딥 네이비 베이스
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.05, blue: 0.10),
                    Color(red: 0.05, green: 0.11, blue: 0.22),
                    Color(red: 0.02, green: 0.04, blue: 0.09)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // 중앙 하단 윈도우 11 네온 블루 블룸 광채
            RadialGradient(
                colors: [Color(red: 0.0, green: 0.60, blue: 1.0).opacity(0.50), Color.clear],
                center: .init(x: 0.5, y: 0.68),
                startRadius: 50,
                endRadius: 750
            )

            // 우측 상단 퍼플 악센트 광채
            RadialGradient(
                colors: [Color(red: 0.35, green: 0.20, blue: 0.90).opacity(0.30), Color.clear],
                center: .init(x: 0.78, y: 0.30),
                startRadius: 40,
                endRadius: 650
            )
        }
    }
}
