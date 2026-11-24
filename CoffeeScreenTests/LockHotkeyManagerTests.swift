import XCTest
import Carbon.HIToolbox
@testable import CoffeeScreen

final class LockHotkeyManagerTests: XCTestCase {

    private let testKey = "com.gorita.coffee-screen.lockHotkey"
    private let useSameKey = "com.gorita.coffee-screen.useSameHotkeyForLock"

    override func setUpWithError() throws {
        UserDefaults.standard.removeObject(forKey: testKey)
        UserDefaults.standard.removeObject(forKey: useSameKey)
    }

    override func tearDownWithError() throws {
        UserDefaults.standard.removeObject(forKey: testKey)
        UserDefaults.standard.removeObject(forKey: useSameKey)
    }

    // MARK: - Default

    func testDefault_WhenNoCustomAndNotSameHotkey_ReturnsNil() {
        XCTAssertNil(LockHotkeyManager.shared.currentHotkey)
    }

    // MARK: - Current Hotkey Tests

    func testCurrentHotkey_WhenNoCustomSet_ReturnsNil() {
        UserDefaults.standard.removeObject(forKey: testKey)

        let manager = LockHotkeyManager.shared
        let current = manager.currentHotkey

        XCTAssertNil(current)
    }

    func testCurrentHotkey_WhenCustomSet_ReturnsCustom() {
        let manager = LockHotkeyManager.shared
        let custom = KeyCombination(
            keyCode: 14,
            keyCharacter: "E",
            modifierFlags: [.command, .option]
        )

        manager.setHotkey(custom)

        XCTAssertEqual(manager.currentHotkey, custom)
    }

    // MARK: - Set Hotkey Tests

    func testSetHotkey_WithValidCombination_ReturnsTrue() {
        let manager = LockHotkeyManager.shared
        let combination = KeyCombination(
            keyCode: 14,
            keyCharacter: "E",
            modifierFlags: [.command]
        )

        XCTAssertTrue(manager.setHotkey(combination))
    }

    func testSetHotkey_WithInvalidCombination_ReturnsFalse() {
        let manager = LockHotkeyManager.shared
        let invalid = KeyCombination(
            keyCode: 14,
            keyCharacter: "E",
            modifierFlags: [.shift]
        )

        XCTAssertFalse(manager.setHotkey(invalid))
    }

    func testSetHotkey_PersistsToUserDefaults() {
        let manager = LockHotkeyManager.shared
        let combination = KeyCombination(
            keyCode: 14,
            keyCharacter: "E",
            modifierFlags: [.command]
        )

        manager.setHotkey(combination)

        XCTAssertNotNil(UserDefaults.standard.data(forKey: testKey))
    }

    func testSetHotkey_PostsChangeNotification() {
        let manager = LockHotkeyManager.shared
        let combination = KeyCombination(
            keyCode: 14,
            keyCharacter: "E",
            modifierFlags: [.command]
        )

        let expectation = expectation(forNotification: LockHotkeyManager.hotkeyDidChangeNotification, object: nil)
        manager.setHotkey(combination)

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Reset to Default Tests

    func testResetToDefault_RemovesCustomSetting() {
        let manager = LockHotkeyManager.shared
        let custom = KeyCombination(
            keyCode: 14,
            keyCharacter: "E",
            modifierFlags: [.command]
        )

        manager.setHotkey(custom)
        manager.resetToDefault()

        XCTAssertNil(manager.currentHotkey)
    }

    // MARK: - Is Custom Hotkey Set Tests

    func testIsCustomHotkeySet_WhenNoCustom_ReturnsFalse() {
        UserDefaults.standard.removeObject(forKey: testKey)

        XCTAssertFalse(LockHotkeyManager.shared.isCustomHotkeySet)
    }

    func testIsCustomHotkeySet_WhenCustomSet_ReturnsTrue() {
        let manager = LockHotkeyManager.shared
        let custom = KeyCombination(
            keyCode: 14,
            keyCharacter: "E",
            modifierFlags: [.command]
        )

        manager.setHotkey(custom)

        XCTAssertTrue(manager.isCustomHotkeySet)
    }
}
