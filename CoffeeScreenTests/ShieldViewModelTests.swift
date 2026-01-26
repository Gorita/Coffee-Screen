import XCTest
import LocalAuthentication
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

    // MARK: - AttemptTouchID Tests

    func testAttemptTouchID_SetsIsAuthenticatingToTrue() {
        sut.attemptTouchID()

        XCTAssertTrue(sut.isAuthenticating)
    }

    func testAttemptTouchID_ClearsExistingError() {
        sut.authError = "기존 에러"

        sut.attemptTouchID()

        XCTAssertNil(sut.authError)
    }

    func testAttemptTouchID_CalledTwice_IgnoresSecondCall() {
        sut.attemptTouchID()
        let firstState = sut.isAuthenticating

        sut.attemptTouchID() // 두 번째 호출은 무시되어야 함

        XCTAssertTrue(firstState)
        XCTAssertTrue(sut.isAuthenticating)
    }
}

// MARK: - Mock AuthManager Tests

@MainActor
final class ShieldViewModelWithMockTests: XCTestCase {

    func testAttemptTouchID_OnSuccess_CallsOnUnlockSuccess() async throws {
        // Mock LAContext that always succeeds
        let mockContext = MockLAContext(shouldSucceed: true)
        let authManager = AuthManager(contextFactory: { mockContext })
        let sut = ShieldViewModel(authManager: authManager)

        var unlockCalled = false
        sut.onUnlockSuccess = { unlockCalled = true }

        sut.attemptTouchID()

        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1초

        XCTAssertTrue(unlockCalled)
        XCTAssertFalse(sut.isAuthenticating)
    }

    func testAttemptTouchID_OnFailure_ShowsPINInput() async throws {
        // Mock LAContext that always fails
        let mockContext = MockLAContext(shouldSucceed: false, errorToThrow: LAError(.authenticationFailed))
        let authManager = AuthManager(contextFactory: { mockContext })
        let sut = ShieldViewModel(authManager: authManager)

        sut.attemptTouchID()

        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1초

        // Touch ID 실패 시 PIN 모드로 전환되어야 함
        XCTAssertFalse(sut.isAuthenticating)
    }

    func testAttemptTouchID_OnCancel_DoesNotShowError() async throws {
        // Mock LAContext that returns cancel error
        let mockContext = MockLAContext(shouldSucceed: false, errorToThrow: LAError(.userCancel))
        let authManager = AuthManager(contextFactory: { mockContext })
        let sut = ShieldViewModel(authManager: authManager)

        sut.attemptTouchID()

        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1초

        XCTAssertFalse(sut.isAuthenticating)
    }
}

// MARK: - Mock LAContext

private class MockLAContext: LAContext {
    private let shouldSucceed: Bool
    private let errorToThrow: Error?
    private let canEvaluate: Bool

    init(shouldSucceed: Bool, errorToThrow: Error? = nil, canEvaluate: Bool = true) {
        self.shouldSucceed = shouldSucceed
        self.errorToThrow = errorToThrow
        self.canEvaluate = canEvaluate
        super.init()
    }

    override func canEvaluatePolicy(_ policy: LAPolicy, error: NSErrorPointer) -> Bool {
        return canEvaluate
    }

    override func evaluatePolicy(_ policy: LAPolicy, localizedReason: String) async throws -> Bool {
        if let error = errorToThrow {
            throw error
        }
        return shouldSucceed
    }
}
