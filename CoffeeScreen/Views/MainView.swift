import SwiftUI

/// 메인 설정 화면
struct MainView: View {
    @EnvironmentObject var viewModel: MainViewModel

    var body: some View {
        VStack(spacing: 24) {
            // 앱 아이콘 및 제목
            VStack(spacing: 8) {
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.brown)

                Text(Constants.appName)
                    .font(.title)
                    .fontWeight(.bold)
            }

            // 상태 표시
            GroupBox {
                HStack {
                    Label(
                        viewModel.appState.isAwake
                            ? String(localized: "status.awake")
                            : String(localized: "status.normal"),
                        systemImage: viewModel.appState.isAwake ? "bolt.fill" : "moon.fill"
                    )
                    .foregroundStyle(viewModel.appState.isAwake ? .green : .secondary)

                    Spacer()

                    Label(
                        "\(viewModel.appState.connectedScreens)",
                        systemImage: "display"
                    )
                    .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            // 잠금 버튼
            Button(action: {
                viewModel.startLock()
            }) {
                Label(Constants.Strings.lockButton, systemImage: "lock.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(viewModel.appState.isLocked)

            Spacer()

            // 전원 경고
            if !viewModel.appState.isPowerConnected {
                Label(Constants.Strings.powerWarning, systemImage: "bolt.slash.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding(24)
        .frame(minWidth: 300, minHeight: 250)
    }
}

#Preview {
    MainView()
        .environmentObject(MainViewModel())
}
