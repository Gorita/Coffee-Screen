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

    // MARK: - AttemptUnlock Tests

    func testAttemptUnlock_SetsIsAuthenticatingToTrue() {
        sut.attemptUnlock()

        XCTAssertTrue(sut.isAuthenticating)
    }

    func testAttemptUnlock_ClearsExistingError() {
        sut.authError = "기존 에러"

        sut.attemptUnlock()

        XCTAssertNil(sut.authError)
    }

    func testAttemptUnlock_CalledTwice_IgnoresSecondCall() {
        sut.attemptUnlock()
        let firstState = sut.isAuthenticating

        sut.attemptUnlock() // 두 번째 호출은 무시되어야 함

        XCTAssertTrue(firstState)
        XCTAssertTrue(sut.isAuthenticating)
    }
}

// MARK: - Mock AuthManager Tests

@MainActor
final class ShieldViewModelWithMockTests: XCTestCase {

    func testAttemptUnlock_OnSuccess_CallsOnUnlockSuccess() async throws {
        // Mock LAContext that always succeeds
        let mockContext = MockLAContext(shouldSucceed: true)
        let authManager = AuthManager(contextFactory: { mockContext })
        let sut = ShieldViewModel(authManager: authManager)

        var unlockCalled = false
        sut.onUnlockSuccess = { unlockCalled = true }

        sut.attemptUnlock()

        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1초

        XCTAssertTrue(unlockCalled)
        XCTAssertFalse(sut.isAuthenticating)
    }

    func testAttemptUnlock_OnFailure_SetsAuthError() async throws {
        // Mock LAContext that always fails
        let mockContext = MockLAContext(shouldSucceed: false, errorToThrow: LAError(.authenticationFailed))
        let authManager = AuthManager(contextFactory: { mockContext })
        let sut = ShieldViewModel(authManager: authManager)

        sut.attemptUnlock()

        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1초

        XCTAssertNotNil(sut.authError)
        XCTAssertFalse(sut.isAuthenticating)
    }

    func testAttemptUnlock_OnCancel_DoesNotShowError() async throws {
        // Mock LAContext that returns cancel error
        let mockContext = MockLAContext(shouldSucceed: false, errorToThrow: LAError(.userCancel))
        let authManager = AuthManager(contextFactory: { mockContext })
        let sut = ShieldViewModel(authManager: authManager)

        sut.attemptUnlock()

        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1초

        XCTAssertNil(sut.authError) // 취소는 에러 표시 안 함
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
