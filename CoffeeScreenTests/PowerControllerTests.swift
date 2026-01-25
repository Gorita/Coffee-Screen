import XCTest
@testable import CoffeeScreen

final class PowerControllerTests: XCTestCase {

    var sut: PowerController!

    override func setUpWithError() throws {
        sut = PowerController()
    }

    override func tearDownWithError() throws {
        sut.stopAwake()
        sut = nil
    }

    // MARK: - Initial State Tests

    func testInitialState_IsNotActive() {
        XCTAssertFalse(sut.isActive)
    }

    // MARK: - startAwake Tests

    func testStartAwake_ReturnsSuccess() {
        let result = sut.startAwake()

        XCTAssertTrue(result.isSuccess)
    }

    func testStartAwake_SetsIsActiveToTrue() {
        _ = sut.startAwake()

        XCTAssertTrue(sut.isActive)
    }

    func testStartAwake_CalledTwice_StillSucceeds() {
        _ = sut.startAwake()
        let result = sut.startAwake()

        XCTAssertTrue(result.isSuccess)
        XCTAssertTrue(sut.isActive)
    }

    // MARK: - stopAwake Tests

    func testStopAwake_AfterStart_SetsIsActiveToFalse() {
        _ = sut.startAwake()

        sut.stopAwake()

        XCTAssertFalse(sut.isActive)
    }

    func testStopAwake_WithoutStart_DoesNotCrash() {
        // 시작하지 않은 상태에서 호출해도 크래시하지 않아야 함
        sut.stopAwake()

        XCTAssertFalse(sut.isActive)
    }

    func testStopAwake_CalledTwice_DoesNotCrash() {
        _ = sut.startAwake()
        sut.stopAwake()

        sut.stopAwake()

        XCTAssertFalse(sut.isActive)
    }
}

// MARK: - Result Extension for Testing

extension Result where Success == Void {
    var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }
}
