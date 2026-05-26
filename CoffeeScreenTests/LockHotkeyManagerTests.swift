import XCTest
import Carbon.HIToolbox
@testable import CoffeeScreen

final class LockHotkeyManagerTests: XCTestCase {

    private let testKey = "com.gorita.coffee-screen.lockHotkey"

    override func tearDownWithError() throws {
        UserDefaults.standard.removeObject(forKey: testKey)
    }

    // MARK: - Default

    func testDefault_IsCmdCtrlL() {
        let defaultCombination = LockHotkeyManager.defaultCombination

        XCTAssertEqual(defaultCombination.keyCode, UInt16(kVK_ANSI_L))
        XCTAssertEqual(defaultCombination.keyCharacter, "L")
        XCTAssertTrue(defaultCombination.modifierFlags.contains(.command))
        XCTAssertTrue(defaultCombination.modifierFlags.contains(.control))
        XCTAssertFalse(defaultCombination.requiresBothShifts)
    }

    // MARK: - Current Hotkey Tests

    func testCurrentHotkey_WhenNoCustomSet_ReturnsDefault() {
        UserDefaults.standard.removeObject(forKey: testKey)

        let manager = LockHotkeyManager.shared
        let current = manager.currentHotkey

        XCTAssertEqual(current, LockHotkeyManager.defaultCombination)
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

        XCTAssertEqual(manager.currentHotkey, LockHotkeyManager.defaultCombination)
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
