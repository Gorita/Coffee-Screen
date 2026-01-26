import SwiftUI

/// 메인 설정 화면
struct MainView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @StateObject private var pinSettingsViewModel = PINSettingsViewModel()
    @FocusState private var focusedField: FocusField?

    enum FocusField {
        case newPIN
        case confirmPIN
    }

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

            // PIN 설정 섹션
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label(String(localized: "pin.settings"), systemImage: "number")
                            .font(.headline)
                        Spacer()
                        if pinSettingsViewModel.isPINSet {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }

                    if pinSettingsViewModel.isPINSet {
                        // PIN이 설정된 경우 - 변경/삭제 옵션
                        HStack(spacing: 8) {
                            Button(String(localized: "pin.change")) {
                                pinSettingsViewModel.showChangePIN()
                            }
                            .buttonStyle(.bordered)
                            .focusEffectDisabled()

                            Button(String(localized: "pin.delete")) {
                                pinSettingsViewModel.deletePIN()
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                            .focusEffectDisabled()
                        }
                    } else {
                        // PIN 설정 안 된 경우 - 설정 필드
                        VStack(spacing: 8) {
                            SecureField(String(localized: "pin.enter"), text: $pinSettingsViewModel.newPIN)
                                .textFieldStyle(.roundedBorder)
                                .frame(maxWidth: .infinity)
                                .focused($focusedField, equals: .newPIN)

                            SecureField(String(localized: "pin.confirmInput"), text: $pinSettingsViewModel.confirmPIN)
                                .textFieldStyle(.roundedBorder)
                                .frame(maxWidth: .infinity)
                                .focused($focusedField, equals: .confirmPIN)

                            Button(String(localized: "pin.set")) {
                                pinSettingsViewModel.setPIN()
                            }
                            .buttonStyle(.bordered)
                            .disabled(!pinSettingsViewModel.canSetPIN)
                        }
                    }

                    // 에러 메시지
                    if let error = pinSettingsViewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    // 성공 메시지
                    if let success = pinSettingsViewModel.successMessage {
                        Text(success)
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
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
            .buttonStyle(.bordered)
            .controlSize(.large)
            .disabled(viewModel.appState.isLocked || !pinSettingsViewModel.isPINSet)

            Spacer()

            // 전원 경고
            if !viewModel.appState.isPowerConnected {
                Label(Constants.Strings.powerWarning, systemImage: "bolt.slash.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding(24)
        .frame(minWidth: 300)
        .fixedSize(horizontal: false, vertical: true)
        .onAppear {
            // PIN 미설정 시 첫 번째 입력 필드로 포커스
            if !pinSettingsViewModel.isPINSet {
                focusedField = .newPIN
            }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
            .environmentObject(MainViewModel())
    }
}
