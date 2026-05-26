import Foundation
import Carbon.HIToolbox

/// 잠금 시작 단축키 관리자 - UserDefaults를 사용한 단축키 저장/로드
final class LockHotkeyManager {

    // MARK: - Constants

    private static let storageKey = "com.gorita.coffee-screen.lockHotkey"

    /// 단축키 변경 알림
    static let hotkeyDidChangeNotification = Notification.Name("com.gorita.coffee-screen.lockHotkeyDidChange")

    /// 기본 잠금 단축키: Cmd + Ctrl + L
    static let defaultCombination = KeyCombination(
        keyCode: UInt16(kVK_ANSI_L),
        keyCharacter: "L",
        modifierFlags: [.command, .control]
    )

    // MARK: - Singleton

    static let shared = LockHotkeyManager()

    private init() {}

    // MARK: - Public Methods

    /// 현재 설정된 단축키 (설정 없으면 기본값)
    var currentHotkey: KeyCombination {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
              let combination = try? JSONDecoder().decode(KeyCombination.self, from: data) else {
            return Self.defaultCombination
        }
        return combination
    }

    /// 커스텀 단축키 저장
    /// - Parameter combination: 저장할 키 조합
    /// - Returns: 성공 여부
    @discardableResult
    func setHotkey(_ combination: KeyCombination) -> Bool {
        guard combination.isValid else { return false }

        guard let data = try? JSONEncoder().encode(combination) else {
            return false
        }

        UserDefaults.standard.set(data, forKey: Self.storageKey)
        NotificationCenter.default.post(name: Self.hotkeyDidChangeNotification, object: nil)
        return true
    }

    /// 기본값으로 복원
    @discardableResult
    func resetToDefault() -> Bool {
        UserDefaults.standard.removeObject(forKey: Self.storageKey)
        NotificationCenter.default.post(name: Self.hotkeyDidChangeNotification, object: nil)
        return true
    }

    /// 커스텀 단축키 설정 여부
    var isCustomHotkeySet: Bool {
        UserDefaults.standard.data(forKey: Self.storageKey) != nil
    }
}
