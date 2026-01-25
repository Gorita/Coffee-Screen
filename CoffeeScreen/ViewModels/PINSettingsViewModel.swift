import Foundation
import SwiftUI

/// PIN 설정 화면의 ViewModel
@MainActor
final class PINSettingsViewModel: ObservableObject {

    // MARK: - Published Properties

    /// 새 PIN 입력값
    @Published var newPIN: String = ""

    /// PIN 확인 입력값
    @Published var confirmPIN: String = ""

    /// 에러 메시지
    @Published var errorMessage: String?

    /// 성공 메시지
    @Published var successMessage: String?

    /// PIN 변경 모드 여부
    @Published var isChangingPIN: Bool = false

    // MARK: - Dependencies

    private let pinManager: PINManager

    // MARK: - Computed Properties

    /// PIN 설정 여부
    var isPINSet: Bool {
        pinManager.isPINSet
    }

    /// PIN 설정 가능 여부
    var canSetPIN: Bool {
        !newPIN.isEmpty &&
        !confirmPIN.isEmpty &&
        newPIN == confirmPIN &&
        pinManager.isValidPIN(newPIN)
    }

    // MARK: - Initialization

    init(pinManager: PINManager = .shared) {
        self.pinManager = pinManager
    }

    // MARK: - Public Methods

    /// PIN 설정
    func setPIN() {
        clearMessages()

        guard newPIN == confirmPIN else {
            errorMessage = String(localized: "error.pin.mismatch")
            return
        }

        guard pinManager.isValidPIN(newPIN) else {
            errorMessage = String(localized: "error.pin.invalid")
            return
        }

        if pinManager.setPIN(newPIN) {
            successMessage = String(localized: "pin.setSuccess")
            clearInput()
            isChangingPIN = false
        } else {
            errorMessage = String(localized: "error.pin.setFailed")
        }
    }

    /// PIN 삭제
    func deletePIN() {
        clearMessages()

        if pinManager.deletePIN() {
            successMessage = String(localized: "pin.deleteSuccess")
        } else {
            errorMessage = String(localized: "error.pin.deleteFailed")
        }
    }

    /// PIN 변경 모드로 전환
    func showChangePIN() {
        // 기존 PIN 삭제 후 새로 설정할 수 있도록
        clearMessages()
        clearInput()
        if pinManager.deletePIN() {
            // PIN 삭제됨 - UI가 자동으로 설정 모드로 전환
        }
    }

    // MARK: - Private Methods

    /// 입력 초기화
    private func clearInput() {
        newPIN = ""
        confirmPIN = ""
    }

    /// 메시지 초기화
    private func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
}
