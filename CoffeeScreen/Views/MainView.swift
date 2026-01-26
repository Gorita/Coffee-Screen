import SwiftUI

/// 메인 설정 화면
struct MainView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @StateObject private var pinSettingsViewModel = PINSettingsViewModel()
    @StateObject private var keyCombinationViewModel = KeyCombinationSettingsViewModel()
    @State private var showEscapeKeyPopover = false

    var body: some View {
        VStack(spacing: 24) {
            // 앱 아이콘 및 제목
            HStack {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.brown)

                    Text(Constants.appName)
                        .font(.title)
                        .fontWeight(.bold)
                }
                Spacer()

                // 비상 탈출 키 설정 버튼 (PIN 설정 시에만 표시)
                if pinSettingsViewModel.isPINSet {
                    Button {
                        showEscapeKeyPopover.toggle()
                    } label: {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 16))
                            .foregroundStyle(.orange)
                    }
                    .buttonStyle(.plain)
                    .help(String(localized: "key.settings"))
                    .popover(isPresented: $showEscapeKeyPopover, arrowEdge: .bottom) {
                        EscapeKeyPopoverView(viewModel: keyCombinationViewModel)
                    }
                }
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
                        // PIN 설정 안 된 경우
                        PINEntryView(viewModel: pinSettingsViewModel)
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

            // 잠금 버튼 (PIN 설정 시에만 표시)
            if pinSettingsViewModel.isPINSet {
                Button(action: {
                    viewModel.startLock()
                }) {
                    Label(Constants.Strings.lockButton, systemImage: "lock.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(viewModel.appState.isLocked)
            }

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
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
            .environmentObject(MainViewModel())
    }
}

// MARK: - PIN 입력 뷰

struct PINEntryView: View {
    @ObservedObject var viewModel: PINSettingsViewModel
    @State private var isConfirmMode: Bool = false
    @State private var inputText: String = ""
    @State private var showResetButton: Bool = false
    @FocusState private var isFocused: Bool

    private let maxLength = 8
    private let minLength = 4

    var body: some View {
        VStack(spacing: 16) {
            // 상태 텍스트
            Text(isConfirmMode ? "입력한 암호를 다시 입력해주세요" : "새 PIN 입력 (4-8자리)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // PIN 도트 표시
            HStack(spacing: 12) {
                ForEach(0..<maxLength, id: \.self) { index in
                    Circle()
                        .fill(index < inputText.count ? Color.primary : Color.clear)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1.5)
                        .frame(width: 16, height: 16)
                }
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .onTapGesture {
                isFocused = true
            }

            // 숨겨진 텍스트 필드 (키보드 입력용)
            TextField("", text: $inputText)
                .focused($isFocused)
                .textFieldStyle(PlainTextFieldStyle())
                .frame(width: 1, height: 1)
                .opacity(0)
                .onChange(of: inputText) { _, newValue in
                    // 숫자만 허용 + 최대 길이 제한
                    let filtered = String(newValue.filter { $0.isNumber }.prefix(maxLength))
                    if filtered != newValue {
                        inputText = filtered
                    }

                    // 새로운 입력이 있을 때만 에러 메시지 지움
                    if !newValue.isEmpty {
                        viewModel.errorMessage = nil
                    }

                    // 확인 모드에서 길이 일치 시 자동 확인
                    if isConfirmMode && inputText.count == viewModel.newPIN.count && inputText.count >= minLength {
                        submitPIN()
                    }
                }
                .onSubmit {
                    // 엔터 키 처리
                    if !isConfirmMode && inputText.count >= minLength {
                        goToConfirm()
                    }
                }

            // 에러 메시지 (고정 높이로 레이아웃 유지)
            Text(viewModel.errorMessage ?? " ")
                .font(.caption)
                .foregroundStyle(viewModel.errorMessage != nil ? .red : .clear)
                .frame(height: 16)

            // 다음/다시설정 버튼 (고정 높이로 레이아웃 유지)
            HStack(spacing: 12) {
                if showResetButton {
                    Button(action: resetToNewPIN) {
                        Text("암호 다시 설정")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                            .frame(minWidth: 100)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 20)
                            .background(Color.secondary.opacity(0.15))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                } else if !isConfirmMode && inputText.count >= minLength {
                    Button(action: goToConfirm) {
                        Text("다음")
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(minWidth: 100)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 20)
                            .background(Color.brown)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(height: 46)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 8)
        .onAppear {
            isFocused = true
        }
    }

    private func goToConfirm() {
        viewModel.newPIN = inputText
        isConfirmMode = true
        inputText = ""
        isFocused = true
    }

    private func submitPIN() {
        viewModel.confirmPIN = inputText
        if viewModel.newPIN == viewModel.confirmPIN {
            viewModel.setPIN()
            isConfirmMode = false
            inputText = ""
            showResetButton = false
        } else {
            viewModel.errorMessage = "입력한 암호가 일치하지 않습니다"
            inputText = ""
            showResetButton = true
            isFocused = true
        }
    }

    private func resetToNewPIN() {
        isConfirmMode = false
        showResetButton = false
        viewModel.newPIN = ""
        viewModel.confirmPIN = ""
        inputText = ""
        viewModel.errorMessage = nil
        isFocused = true
    }
}

// MARK: - 비상 탈출 키 팝오버 뷰

struct EscapeKeyPopoverView: View {
    @ObservedObject var viewModel: KeyCombinationSettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 제목
            Label(String(localized: "key.settings"), systemImage: "keyboard")
                .font(.headline)

            // 안내 문구
            Text("key.info.description")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            // 키 설정 뷰
            KeyRecorderView(viewModel: viewModel)
        }
        .padding(16)
        .frame(width: 300)
    }
}
