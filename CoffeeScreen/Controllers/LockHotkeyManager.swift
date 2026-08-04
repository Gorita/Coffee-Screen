import Foundation
import Carbon.HIToolbox

/// 잠금 시작 단축키 관리자 - UserDefaults를 사용한 단축키 저장/로드
final class LockHotkeyManager {

    // MARK: - Constants

    private static let storageKey = "com.gorita.coffee-screen.lockHotkey"
    private static let useSameHotkeyKey = "com.gorita.coffee-screen.useSameHotkeyForLock"

    /// 단축키 변경 알림
    static let hotkeyDidChangeNotification = Notification.Name("com.gorita.coffee-screen.lockHotkeyDidChange")

    /// 해제 단축키와 동일한 단축키로 잠금 사용 여부 (기본값 false)
    var useSameHotkeyForLock: Bool {
        get {
            UserDefaults.standard.bool(forKey: Self.useSameHotkeyKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Self.useSameHotkeyKey)
            if newValue {
                // 동일 키 사용 체크 시 해제 단축키와 완벽히 똑같은 키 조합으로 자동 동기화
                let escapeKey = KeyCombinationManager.shared.currentKeyCombination
                if let data = try? JSONEncoder().encode(escapeKey) {
                    UserDefaults.standard.set(data, forKey: Self.storageKey)
                }
            }
            NotificationCenter.default.post(name: Self.hotkeyDidChangeNotification, object: nil)
        }
    }

    // MARK: - Singleton

    static let shared = LockHotkeyManager()

    private init() {}

    // MARK: - Public Methods

    /// 현재 설정된 잠금 단축키 (동일 키 사용이 아니거나 설정이 없으면 nil - 기본값 없음)
    var currentHotkey: KeyCombination? {
        if useSameHotkeyForLock {
            return KeyCombinationManager.shared.currentKeyCombination
        }
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
              let combination = try? JSONDecoder().decode(KeyCombination.self, from: data) else {
            return nil
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
