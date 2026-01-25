import XCTest
@testable import CoffeeScreen

@MainActor
final class ShieldViewModelTests: XCTestCase {

    var sut: ShieldViewModel!

    override func setUpWithError() throws {
        sut = ShieldViewModel()
    }

    override func tearDownWithError() throws {
        sut = nil
    }

    // MARK: - Initial State Tests

    func testInitialState_IsNotAuthenticating() {
        XCTAssertFalse(sut.isAuthenticating)
    }

    func testInitialState_HasNoError() {
        XCTAssertNil(sut.authError)
    }

    // MARK: - Unlock Callback Tests

    func testOnUnlockSuccess_IsNilByDefault() {
        XCTAssertNil(sut.onUnlockSuccess)
    }

    func testOnUnlockSuccess_CanBeSet() {
        var callbackCalled = false
        sut.onUnlockSuccess = {
            callbackCalled = true
        }

        sut.onUnlockSuccess?()

        XCTAssertTrue(callbackCalled)
    }

    // MARK: - Error State Tests

    func testSetAuthError_UpdatesState() {
        sut.authError = "테스트 에러"

        XCTAssertEqual(sut.authError, "테스트 에러")
    }

    func testClearError_RemovesError() {
        sut.authError = "테스트 에러"

        sut.clearError()

        XCTAssertNil(sut.authError)
    }
}
