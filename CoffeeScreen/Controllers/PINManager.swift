import Foundation

/// PIN 관리자 - UserDefaults를 사용한 PIN 저장/검증
final class PINManager {

    // MARK: - Constants

    private static let pinKey = "com.gorita.coffee-screen.userPIN"

    // MARK: - Singleton

    static let shared = PINManager()

    private init() {}

    // MARK: - Public Methods

    /// PIN이 설정되어 있는지 확인
    var isPINSet: Bool {
        return loadPIN() != nil
    }

    /// PIN 설정
    /// - Parameter pin: 설정할 PIN (4-8자리 숫자)
    /// - Returns: 성공 여부
    @discardableResult
    func setPIN(_ pin: String) -> Bool {
        guard isValidPIN(pin) else { return false }

        UserDefaults.standard.set(pin, forKey: Self.pinKey)
        return true
    }

    /// PIN 검증
    /// - Parameter pin: 검증할 PIN
    /// - Returns: 일치 여부
    func verifyPIN(_ pin: String) -> Bool {
        guard let storedPIN = loadPIN() else { return false }
        return pin == storedPIN
    }

    /// PIN 삭제
    @discardableResult
    func deletePIN() -> Bool {
        UserDefaults.standard.removeObject(forKey: Self.pinKey)
        return true
    }

    /// PIN 유효성 검사 (4-8자리 숫자)
    func isValidPIN(_ pin: String) -> Bool {
        let pinRegex = "^[0-9]{4,8}$"
        return pin.range(of: pinRegex, options: .regularExpression) != nil
    }

    // MARK: - Private Methods

    /// UserDefaults에서 PIN 로드
    private func loadPIN() -> String? {
        return UserDefaults.standard.string(forKey: Self.pinKey)
    }
}
