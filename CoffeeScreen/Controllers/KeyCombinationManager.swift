import Foundation

/// 비상 탈출 키 조합 관리자 - UserDefaults를 사용한 키 조합 저장/로드
final class KeyCombinationManager {

    // MARK: - Constants

    private static let storageKey = "com.gorita.coffee-screen.emergencyKeyCombination"

    // MARK: - Singleton

    static let shared = KeyCombinationManager()

    private init() {}

    // MARK: - Public Methods

    /// 현재 설정된 키 조합 반환 (설정 없으면 기본값)
    var currentKeyCombination: KeyCombination {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
              let combination = try? JSONDecoder().decode(KeyCombination.self, from: data) else {
            return .default
        }
        return combination
    }

    /// 커스텀 키 조합 저장
    /// - Parameter combination: 저장할 키 조합
    /// - Returns: 성공 여부
    @discardableResult
    func setKeyCombination(_ combination: KeyCombination) -> Bool {
        guard combination.isValid else { return false }

        guard let data = try? JSONEncoder().encode(combination) else {
            return false
        }

        UserDefaults.standard.set(data, forKey: Self.storageKey)
        return true
    }

    /// 기본값으로 복원
    @discardableResult
    func resetToDefault() -> Bool {
        UserDefaults.standard.removeObject(forKey: Self.storageKey)
        return true
    }

    /// 커스텀 키가 설정되어 있는지 확인
    var isCustomKeySet: Bool {
        UserDefaults.standard.data(forKey: Self.storageKey) != nil
    }
}
