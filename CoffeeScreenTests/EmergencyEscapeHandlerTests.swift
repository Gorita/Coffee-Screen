import XCTest
@testable import CoffeeScreen

@MainActor
final class EmergencyEscapeHandlerTests: XCTestCase {

    var sut: EmergencyEscapeHandler!

    override func setUpWithError() throws {
        sut = EmergencyEscapeHandler()
    }

    override func tearDownWithError() throws {
        sut?.stop()
        sut = nil
    }

    // MARK: - Initial State Tests

    func testInitialState_IsNotMonitoring() {
        XCTAssertFalse(sut.isMonitoring)
    }

    func testInitialState_OnEscapeIsNil() {
        XCTAssertNil(sut.onEscape)
    }

    // MARK: - Start/Stop Tests

    func testStart_SetsIsMonitoringToTrue() {
        sut.start()

        XCTAssertTrue(sut.isMonitoring)
    }

    func testStart_CalledTwice_StillMonitoring() {
        sut.start()
        sut.start()

        XCTAssertTrue(sut.isMonitoring)
    }

    func testStop_SetsIsMonitoringToFalse() {
        sut.start()
        sut.stop()

        XCTAssertFalse(sut.isMonitoring)
    }

    func testStop_WithoutStart_DoesNotCrash() {
        sut.stop()

        XCTAssertFalse(sut.isMonitoring)
    }

    func testStop_CalledTwice_DoesNotCrash() {
        sut.start()
        sut.stop()
        sut.stop()

        XCTAssertFalse(sut.isMonitoring)
    }

    // MARK: - Callback Tests

    func testOnEscape_CanBeSet() {
        var called = false
        sut.onEscape = { called = true }

        XCTAssertNotNil(sut.onEscape)
        sut.onEscape?()
        XCTAssertTrue(called)
    }

    // MARK: - Key Combination Tests

    func testIsEmergencyKeyCombination_WithCorrectKeys_ReturnsTrue() {
        // Cmd + L 키 (keyCode 0x25 = 37)
        // 양쪽 Shift가 눌린 상태 (.shift 플래그 + 추가 조건)
        let result = sut.isEmergencyKeyCombination(
            keyCode: 0x25,
            modifierFlags: [.command, .shift],
            bothShiftsPressed: true
        )

        XCTAssertTrue(result)
    }

    func testIsEmergencyKeyCombination_WithoutBothShifts_ReturnsFalse() {
        let result = sut.isEmergencyKeyCombination(
            keyCode: 0x25,
            modifierFlags: [.command, .shift],
            bothShiftsPressed: false
        )

        XCTAssertFalse(result)
    }

    func testIsEmergencyKeyCombination_WithWrongKey_ReturnsFalse() {
        let result = sut.isEmergencyKeyCombination(
            keyCode: 0x00, // A 키
            modifierFlags: [.command, .shift],
            bothShiftsPressed: true
        )

        XCTAssertFalse(result)
    }

    func testIsEmergencyKeyCombination_WithoutCommand_ReturnsFalse() {
        let result = sut.isEmergencyKeyCombination(
            keyCode: 0x25,
            modifierFlags: [.shift],
            bothShiftsPressed: true
        )

        XCTAssertFalse(result)
    }
}
