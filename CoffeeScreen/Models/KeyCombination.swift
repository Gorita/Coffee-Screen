import AppKit
import Carbon.HIToolbox

/// 키 조합 데이터 모델
struct KeyCombination: Codable, Equatable {

    // MARK: - Properties

    /// 키 코드 (Carbon HIToolbox 기준)
    let keyCode: UInt16

    /// 키 문자 (표시용)
    let keyCharacter: String

    /// 수정자 키 플래그 (raw value로 저장)
    let modifierFlagsRawValue: UInt

    /// 양쪽 Shift 키 필요 여부
    let requiresBothShifts: Bool

    // MARK: - Computed Properties

    /// 수정자 키 플래그
    var modifierFlags: NSEvent.ModifierFlags {
        NSEvent.ModifierFlags(rawValue: modifierFlagsRawValue)
    }

    /// 표시 문자열 (예: "Shift+Shift+Cmd+L")
    var displayString: String {
        var parts: [String] = []

        if requiresBothShifts {
            parts.append("Shift+Shift")
        } else if modifierFlags.contains(.shift) {
            parts.append("Shift")
        }

        if modifierFlags.contains(.control) {
            parts.append("Ctrl")
        }

        if modifierFlags.contains(.option) {
            parts.append("Option")
        }

        if modifierFlags.contains(.command) {
            parts.append("Cmd")
        }

        parts.append(keyCharacter.uppercased())

        return parts.joined(separator: "+")
    }

    /// 유효성 검사 (Cmd 또는 Ctrl 필수)
    var isValid: Bool {
        modifierFlags.contains(.command) || modifierFlags.contains(.control)
    }

    // MARK: - Initialization

    init(
        keyCode: UInt16,
        keyCharacter: String,
        modifierFlags: NSEvent.ModifierFlags,
        requiresBothShifts: Bool = false
    ) {
        self.keyCode = keyCode
        self.keyCharacter = keyCharacter
        self.modifierFlagsRawValue = modifierFlags.rawValue
        self.requiresBothShifts = requiresBothShifts
    }

    // MARK: - Default

    /// 기본 비상 탈출 키: 양쪽 Shift + Cmd + L
    static let `default` = KeyCombination(
        keyCode: UInt16(kVK_ANSI_L),
        keyCharacter: "L",
        modifierFlags: [.shift, .command],
        requiresBothShifts: true
    )
}
