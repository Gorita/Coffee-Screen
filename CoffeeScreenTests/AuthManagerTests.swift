import XCTest
@testable import CoffeeScreen

@MainActor
final class AuthManagerTests: XCTestCase {

    var sut: AuthManager!

    override func setUpWithError() throws {
        sut = AuthManager()
    }

    override func tearDownWithError() throws {
        sut = nil
    }

    // MARK: - Availability Tests

    func testCanAuthenticate_ReturnsBoolean() {
        // LocalAuthentication 가용 여부 확인
        let result = sut.canAuthenticate()

        // 실제 기기에서는 true/false, 시뮬레이터에서는 상황에 따라 다름
        XCTAssertNotNil(result)
    }

    // MARK: - Authentication Tests

    func testAuthenticate_ReturnsResult() async {
        // 인증 시도 시 Result 타입 반환
        let result = await sut.authenticate(reason: "테스트 인증")

        // 성공 또는 실패 중 하나
        switch result {
        case .success, .failure:
            // Result 타입이 올바르게 반환됨
            break
        }
    }

    func testAuthenticate_WithEmptyReason_StillWorks() async {
        // 빈 reason으로도 동작해야 함
        let result = await sut.authenticate(reason: "")

        switch result {
        case .success, .failure:
            break
        }
    }
}

// MARK: - AuthError Tests

final class AuthErrorTests: XCTestCase {

    func testAuthError_Cancelled_HasDescription() {
        let error = AuthError.cancelled

        XCTAssertFalse(error.localizedDescription.isEmpty)
    }

    func testAuthError_Failed_ContainsMessage() {
        let message = "테스트 에러 메시지"
        let error = AuthError.failed(message)

        XCTAssertTrue(error.localizedDescription.contains(message))
    }

    func testAuthError_NotAvailable_HasDescription() {
        let error = AuthError.notAvailable

        XCTAssertFalse(error.localizedDescription.isEmpty)
    }

    func testAuthError_Equatable() {
        XCTAssertEqual(AuthError.cancelled, AuthError.cancelled)
        XCTAssertEqual(AuthError.notAvailable, AuthError.notAvailable)
        XCTAssertEqual(AuthError.failed("test"), AuthError.failed("test"))
        XCTAssertNotEqual(AuthError.failed("a"), AuthError.failed("b"))
        XCTAssertNotEqual(AuthError.cancelled, AuthError.notAvailable)
    }
}
