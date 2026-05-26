import XCTest
import Carbon.HIToolbox
@testable import CoffeeScreen

@MainActor
final class LockHotkeyHandlerTests: XCTestCase {

    override func tearDown() async throws {
        UserDefaults.standard.removeObject(forKey: "com.gorita.coffee-screen.lockHotkey")
    }

    // MARK: - Carbon Modifier Conversion

    func testCarbonModifiers_Command() {
        let result = LockHotkeyHandler.carbonModifiers(from: [.command])
        XCTAssertEqual(result, UInt32(cmdKey))
    }

    func testCarbonModifiers_Control() {
        let result = LockHotkeyHandler.carbonModifiers(from: [.control])
        XCTAssertEqual(result, UInt32(controlKey))
    }

    func testCarbonModifiers_Option() {
        let result = LockHotkeyHandler.carbonModifiers(from: [.option])
        XCTAssertEqual(result, UInt32(optionKey))
    }

    func testCarbonModifiers_Shift() {
        let result = LockHotkeyHandler.carbonModifiers(from: [.shift])
        XCTAssertEqual(result, UInt32(shiftKey))
    }

    func testCarbonModifiers_CommandControl() {
        let result = LockHotkeyHandler.carbonModifiers(from: [.command, .control])
        XCTAssertEqual(result, UInt32(cmdKey) | UInt32(controlKey))
    }

    func testCarbonModifiers_Empty() {
        let result = LockHotkeyHandler.carbonModifiers(from: [])
        XCTAssertEqual(result, 0)
    }

    // MARK: - Lifecycle (start/stop은 RegisterEventHotKey가 NSApp 컨텍스트를 요구해 xctest에서 검증 불가 — 통합 테스트 영역)

    func testInitialState_IsNotMonitoring() {
        let handler = LockHotkeyHandler()
        XCTAssertFalse(handler.isMonitoring)
    }

    func testReload_WhenNotStarted_ReturnsFalse() {
        let handler = LockHotkeyHandler()
        XCTAssertFalse(handler.reload())
    }
}
