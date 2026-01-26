import XCTest
import AppKit
@testable import CoffeeScreen

final class KeyCombinationTests: XCTestCase {

    // MARK: - Display String Tests

    func testDisplayString_WithDefaultCombination_ShowsCorrectFormat() {
        let combination = KeyCombination.default

        XCTAssertEqual(combination.displayString, "Shift+Shift+Cmd+L")
    }

    func testDisplayString_WithSingleShift_ShowsCorrectFormat() {
        let combination = KeyCombination(
            keyCode: 0x25,
            keyCharacter: "L",
            modifierFlags: [.shift, .command],
            requiresBothShifts: false
        )

        XCTAssertEqual(combination.displayString, "Shift+Cmd+L")
    }

    func testDisplayString_WithAllModifiers_ShowsCorrectOrder() {
        let combination = KeyCombination(
            keyCode: 14, // E
            keyCharacter: "E",
            modifierFlags: [.shift, .control, .option, .command],
            requiresBothShifts: false
        )

        XCTAssertEqual(combination.displayString, "Shift+Ctrl+Option+Cmd+E")
    }

    func testDisplayString_WithoutShift_ShowsCorrectFormat() {
        let combination = KeyCombination(
            keyCode: 14,
            keyCharacter: "E",
            modifierFlags: [.command, .option],
            requiresBothShifts: false
        )

        XCTAssertEqual(combination.displayString, "Option+Cmd+E")
    }

    // MARK: - Validation Tests

    func testIsValid_WithCommand_ReturnsTrue() {
        let combination = KeyCombination(
            keyCode: 14,
            keyCharacter: "E",
            modifierFlags: [.command],
            requiresBothShifts: false
        )

        XCTAssertTrue(combination.isValid)
    }

    func testIsValid_WithControl_ReturnsTrue() {
        let combination = KeyCombination(
            keyCode: 14,
            keyCharacter: "E",
            modifierFlags: [.control],
            requiresBothShifts: false
        )

        XCTAssertTrue(combination.isValid)
    }

    func testIsValid_WithBothCommandAndControl_ReturnsTrue() {
        let combination = KeyCombination(
            keyCode: 14,
            keyCharacter: "E",
            modifierFlags: [.command, .control],
            requiresBothShifts: false
        )

        XCTAssertTrue(combination.isValid)
    }

    func testIsValid_WithOnlyShift_ReturnsFalse() {
        let combination = KeyCombination(
            keyCode: 14,
            keyCharacter: "E",
            modifierFlags: [.shift],
            requiresBothShifts: false
        )

        XCTAssertFalse(combination.isValid)
    }

    func testIsValid_WithOnlyOption_ReturnsFalse() {
        let combination = KeyCombination(
            keyCode: 14,
            keyCharacter: "E",
            modifierFlags: [.option],
            requiresBothShifts: false
        )

        XCTAssertFalse(combination.isValid)
    }

    // MARK: - Default Combination Tests

    func testDefault_HasCorrectKeyCode() {
        // L 키 코드 = 0x25 = 37
        XCTAssertEqual(KeyCombination.default.keyCode, 37)
    }

    func testDefault_RequiresBothShifts() {
        XCTAssertTrue(KeyCombination.default.requiresBothShifts)
    }

    func testDefault_ContainsCommand() {
        XCTAssertTrue(KeyCombination.default.modifierFlags.contains(.command))
    }

    func testDefault_ContainsShift() {
        XCTAssertTrue(KeyCombination.default.modifierFlags.contains(.shift))
    }

    func testDefault_IsValid() {
        XCTAssertTrue(KeyCombination.default.isValid)
    }

    // MARK: - Codable Tests

    func testCodable_EncodesAndDecodesCorrectly() throws {
        let original = KeyCombination(
            keyCode: 14,
            keyCharacter: "E",
            modifierFlags: [.command, .option],
            requiresBothShifts: false
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(KeyCombination.self, from: data)

        XCTAssertEqual(decoded, original)
    }

    func testCodable_DefaultCombination_EncodesAndDecodesCorrectly() throws {
        let original = KeyCombination.default

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(KeyCombination.self, from: data)

        XCTAssertEqual(decoded, original)
    }

    // MARK: - Equatable Tests

    func testEquatable_SameCombinations_AreEqual() {
        let combination1 = KeyCombination(
            keyCode: 14,
            keyCharacter: "E",
            modifierFlags: [.command],
            requiresBothShifts: false
        )

        let combination2 = KeyCombination(
            keyCode: 14,
            keyCharacter: "E",
            modifierFlags: [.command],
            requiresBothShifts: false
        )

        XCTAssertEqual(combination1, combination2)
    }

    func testEquatable_DifferentKeyCodes_AreNotEqual() {
        let combination1 = KeyCombination(
            keyCode: 14,
            keyCharacter: "E",
            modifierFlags: [.command],
            requiresBothShifts: false
        )

        let combination2 = KeyCombination(
            keyCode: 15,
            keyCharacter: "R",
            modifierFlags: [.command],
            requiresBothShifts: false
        )

        XCTAssertNotEqual(combination1, combination2)
    }
}
