import XCTest
@testable import CoffeeScreen

final class CoffeeScreenTests: XCTestCase {

    override func setUpWithError() throws {
        // 각 테스트 전 초기화
    }

    override func tearDownWithError() throws {
        // 각 테스트 후 정리
    }

    // MARK: - AppState Tests

    func testAppStateInitialValues() throws {
        let state = AppState()

        XCTAssertFalse(state.isLocked)
        XCTAssertFalse(state.isAwake)
        XCTAssertTrue(state.isPowerConnected)
        XCTAssertEqual(state.connectedScreens, 1)
        XCTAssertNil(state.lastError)
    }

    // MARK: - MainViewModel Tests

    @MainActor
    func testMainViewModelStartLock() throws {
        let viewModel = MainViewModel()

        XCTAssertFalse(viewModel.appState.isLocked)
        XCTAssertFalse(viewModel.appState.isAwake)

        viewModel.startLock()

        XCTAssertTrue(viewModel.appState.isLocked)
        XCTAssertTrue(viewModel.appState.isAwake)
    }

    @MainActor
    func testMainViewModelStopLock() throws {
        let viewModel = MainViewModel()
        viewModel.startLock()

        viewModel.stopLock()

        XCTAssertFalse(viewModel.appState.isLocked)
        XCTAssertFalse(viewModel.appState.isAwake)
    }
}
