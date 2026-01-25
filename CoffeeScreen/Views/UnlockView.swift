import SwiftUI

/// 잠금 해제 UI
struct UnlockView: View {
    @ObservedObject var viewModel: ShieldViewModel

    var body: some View {
        VStack(spacing: 24) {
            // 잠금 아이콘
            Image(systemName: "lock.fill")
                .font(.system(size: 64))
                .foregroundStyle(.white.opacity(0.8))

            // 앱 이름
            Text(Constants.appName)
                .font(.title)
                .fontWeight(.medium)
                .foregroundStyle(.white)

            // 안내 메시지
            Text(Constants.Strings.unlockReason)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))

            // 잠금 해제 버튼
            Button(action: {
                viewModel.attemptUnlock()
            }) {
                HStack {
                    if viewModel.isAuthenticating {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Image(systemName: "faceid")
                    }
                    Text(Constants.Strings.unlockButton)
                }
                .frame(width: 160)
                .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .disabled(viewModel.isAuthenticating)

            // 에러 메시지
            if let error = viewModel.authError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.top, 8)
            }
        }
        .padding(40)
    }
}

#Preview {
    ZStack {
        Color.black
        UnlockView(viewModel: ShieldViewModel())
    }
}
