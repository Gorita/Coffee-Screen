import XCTest
@testable import CoffeeScreen

final class KeyCombinationManagerTests: XCTestCase {

    private let testKey = "com.gorita.coffee-screen.emergencyKeyCombination"

    override func tearDownWithError() throws {
        // 테스트 후 UserDefaults 정리
        UserDefaults.standard.removeObject(forKey: testKey)
    }

    // MARK: - Current Key Combination Tests

    func testCurrentKeyCombination_WhenNoCustomSet_ReturnsDefault() {
        // 먼저 기존 설정 제거
        UserDefaults.standard.removeObject(forKey: testKey)

        let manager = KeyCombinationManager.shared
        let current = manager.currentKeyCombination

        XCTAssertEqual(current, KeyCombination.default)
    }

    func testCurrentKeyCombination_WhenCustomSet_ReturnsCustom() {
        let manager = KeyCombinationManager.shared
        let custom = KeyCombination(
            keyCode: 14,
            keyCharacter: "E",
            modifierFlags: [.command, .option],
            requiresBothShifts: false
        )

        manager.setKeyCombination(custom)
        let current = manager.currentKeyCombination

        XCTAssertEqual(current, custom)
    }

    // MARK: - Set Key Combination Tests

    func testSetKeyCombination_WithValidCombination_ReturnsTrue() {
        let manager = KeyCombinationManager.shared
        let combination = KeyCombination(
            keyCode: 14,
            keyCharacter: "E",
            modifierFlags: [.command],
            requiresBothShifts: false
        )

        let result = manager.setKeyCombination(combination)

        XCTAssertTrue(result)
    }

    func testSetKeyCombination_WithInvalidCombination_ReturnsFalse() {
        let manager = KeyCombinationManager.shared
        let invalid = KeyCombination(
            keyCode: 14,
            keyCharacter: "E",
            modifierFlags: [.shift], // Cmd나 Ctrl 없음
            requiresBothShifts: false
        )

        let result = manager.setKeyCombination(invalid)

        XCTAssertFalse(result)
    }

    func testSetKeyCombination_PersistsToUserDefaults() {
        let manager = KeyCombinationManager.shared
        let combination = KeyCombination(
            keyCode: 14,
            keyCharacter: "E",
            modifierFlags: [.command],
            requiresBothShifts: false
        )

        manager.setKeyCombination(combination)

        // UserDefaults에 데이터가 저장되었는지 확인
        XCTAssertNotNil(UserDefaults.standard.data(forKey: testKey))
    }

    // MARK: - Reset to Default Tests

    func testResetToDefault_RemovesCustomSetting() {
        let manager = KeyCombinationManager.shared
        let custom = KeyCombination(
            keyCode: 14,
            keyCharacter: "E",
            modifierFlags: [.command],
            requiresBothShifts: false
        )

        manager.setKeyCombination(custom)
        manager.resetToDefault()

        let current = manager.currentKeyCombination
        XCTAssertEqual(current, KeyCombination.default)
    }

    func testResetToDefault_ReturnsTrue() {
        let manager = KeyCombinationManager.shared

        let result = manager.resetToDefault()

        XCTAssertTrue(result)
    }

    // MARK: - Is Custom Key Set Tests

    func testIsCustomKeySet_WhenNoCustom_ReturnsFalse() {
        UserDefaults.standard.removeObject(forKey: testKey)

        let manager = KeyCombinationManager.shared

        XCTAssertFalse(manager.isCustomKeySet)
    }

    func testIsCustomKeySet_WhenCustomSet_ReturnsTrue() {
        let manager = KeyCombinationManager.shared
        let custom = KeyCombination(
            keyCode: 14,
            keyCharacter: "E",
            modifierFlags: [.command],
            requiresBothShifts: false
        )

        manager.setKeyCombination(custom)

        XCTAssertTrue(manager.isCustomKeySet)
    }
}
