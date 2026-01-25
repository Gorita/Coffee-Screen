import XCTest

final class CoffeeScreenUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    @MainActor
    func testMainViewAppears() throws {
        let app = XCUIApplication()
        app.launch()

        // 앱 제목 확인
        XCTAssertTrue(app.staticTexts["Coffee-Screen"].exists)

        // 잠금 버튼 확인
        XCTAssertTrue(app.buttons["화면 잠금"].exists || app.buttons["Lock Screen"].exists)
    }

    @MainActor
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
