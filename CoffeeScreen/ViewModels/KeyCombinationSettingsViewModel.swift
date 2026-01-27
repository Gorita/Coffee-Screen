import Foundation
import SwiftUI
import AppKit

/// 비상 탈출 키 설정 화면의 ViewModel
@MainActor
final class KeyCombinationSettingsViewModel: ObservableObject {

    // MARK: - Published Properties

    /// 현재 키 표시 문자열
    @Published private(set) var currentKeyDisplay: String = ""

    /// 녹화 모드 여부
    @Published var isRecording: Bool = false

    /// 녹화된 키 조합
    @Published var recordedCombination: KeyCombination?

    /// 에러 메시지
    @Published var errorMessage: String?

    /// 성공 메시지
    @Published var successMessage: String?

    /// 왼쪽 Shift 키 눌림 상태
    @Published var leftShiftPressed: Bool = false

    /// 오른쪽 Shift 키 눌림 상태
    @Published var rightShiftPressed: Bool = false

    // MARK: - Dependencies

    private let manager: KeyCombinationManager

    // MARK: - Computed Properties

    /// 양쪽 Shift 키가 모두 눌렸는지
    var bothShiftsPressed: Bool {
        leftShiftPressed && rightShiftPressed
    }

    /// 녹화된 키 저장 가능 여부
    var canSave: Bool {
        recordedCombination?.isValid == true
    }

    /// 녹화된 키 표시 문자열
    var recordedKeyDisplay: String {
        recordedCombination?.displayString ?? ""
    }

    // MARK: - Initialization

    init(manager: KeyCombinationManager = .shared) {
        self.manager = manager
        updateCurrentKeyDisplay()
    }

    // MARK: - Public Methods

    /// 녹화 모드 시작
    func startRecording() {
        clearMessages()
        isRecording = true
        recordedCombination = nil
        leftShiftPressed = false
        rightShiftPressed = false
    }

    /// 녹화 모드 취소
    func cancelRecording() {
        isRecording = false
        recordedCombination = nil
        leftShiftPressed = false
        rightShiftPressed = false
    }

    /// 녹화된 키 조합 저장
    func saveRecordedCombination() {
        clearMessages()

        guard let combination = recordedCombination else {
            errorMessage = "No key combination recorded"
            return
        }

        guard combination.isValid else {
            errorMessage = "Must include Cmd or Ctrl"
            return
        }

        if manager.setKeyCombination(combination) {
            successMessage = "Key saved"
            isRecording = false
            recordedCombination = nil
            updateCurrentKeyDisplay()
        } else {
            errorMessage = "Failed to save key"
        }
    }

    /// Reset to default
    func resetToDefault() {
        clearMessages()

        if manager.resetToDefault() {
            successMessage = "Reset to default"
            updateCurrentKeyDisplay()
        }
    }

    /// 키 이벤트 처리 (녹화 중)
    func handleKeyEvent(keyCode: UInt16, characters: String?, modifierFlags: NSEvent.ModifierFlags) {
        guard isRecording else { return }

        let keyChar = characters?.uppercased() ?? keyCodeToCharacter(keyCode)

        let combination = KeyCombination(
            keyCode: keyCode,
            keyCharacter: keyChar,
            modifierFlags: modifierFlags,
            requiresBothShifts: bothShiftsPressed
        )

        recordedCombination = combination
    }

    /// Shift 키 상태 업데이트
    func updateShiftState(keyCode: UInt16, isPressed: Bool) {
        // Left Shift: 56, Right Shift: 60
        if keyCode == 56 {
            leftShiftPressed = isPressed
        } else if keyCode == 60 {
            rightShiftPressed = isPressed
        }
    }

    // MARK: - Private Methods

    /// 현재 키 표시 업데이트
    private func updateCurrentKeyDisplay() {
        currentKeyDisplay = manager.currentKeyCombination.displayString
    }

    /// 메시지 초기화
    private func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }

    /// 키 코드를 문자로 변환
    private func keyCodeToCharacter(_ keyCode: UInt16) -> String {
        // 일반적인 키 코드 매핑
        let keyMap: [UInt16: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
            23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0",
            30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P", 36: "Return",
            37: "L", 38: "J", 39: "'", 40: "K", 41: ";", 42: "\\", 43: ",",
            44: "/", 45: "N", 46: "M", 47: ".", 48: "Tab", 49: "Space",
            50: "`", 51: "Delete", 53: "Esc",
            // Function keys
            122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6",
            98: "F7", 100: "F8", 101: "F9", 109: "F10", 103: "F11", 111: "F12",
            // Arrow keys
            123: "←", 124: "→", 125: "↓", 126: "↑"
        ]

        return keyMap[keyCode] ?? "Key\(keyCode)"
    }
}
