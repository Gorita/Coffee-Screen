import XCTest
@testable import CoffeeScreen

@MainActor
final class ShieldWindowControllerTests: XCTestCase {

    var sut: ShieldWindowController!

    override func setUpWithError() throws {
        sut = ShieldWindowController()
    }

    override func tearDownWithError() throws {
        sut?.hideShields()
        sut = nil
    }

    // MARK: - Initial State Tests

    func testInitialState_HasNoShields() {
        XCTAssertEqual(sut.shieldCount, 0)
        XCTAssertFalse(sut.isShowing)
    }

    // MARK: - hideShields Tests

    func testHideShields_WithoutShow_DoesNotCrash() {
        sut.hideShields()

        XCTAssertEqual(sut.shieldCount, 0)
        XCTAssertFalse(sut.isShowing)
    }

    func testHideShields_SetsIsShowingToFalse() {
        // hideShields 호출 후 상태 확인
        sut.hideShields()

        XCTAssertFalse(sut.isShowing)
    }
}

// MARK: - ShieldWindow Tests

@MainActor
final class ShieldWindowTests: XCTestCase {

    func testShieldWindow_CanBecomeKey() {
        guard let screen = NSScreen.main else {
            XCTFail("No main screen available")
            return
        }

        let window = ShieldWindow(screen: screen)

        XCTAssertTrue(window.canBecomeKey)
        XCTAssertTrue(window.canBecomeMain)

        window.close()
    }

    func testShieldWindow_HasCorrectLevel() {
        guard let screen = NSScreen.main else {
            XCTFail("No main screen available")
            return
        }

        let window = ShieldWindow(screen: screen)

        XCTAssertEqual(window.level.rawValue, Constants.shieldWindowLevel)

        window.close()
    }

    func testShieldWindow_HasBlackBackground() {
        guard let screen = NSScreen.main else {
            XCTFail("No main screen available")
            return
        }

        let window = ShieldWindow(screen: screen)

        XCTAssertEqual(window.backgroundColor, .black)
        XCTAssertTrue(window.isOpaque)

        window.close()
    }

    func testShieldWindow_CanJoinAllSpaces() {
        guard let screen = NSScreen.main else {
            XCTFail("No main screen available")
            return
        }

        let window = ShieldWindow(screen: screen)

        XCTAssertTrue(window.collectionBehavior.contains(.canJoinAllSpaces))

        window.close()
    }
}
