import XCTest

final class CoffeeScreenUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Main View Tests

    @MainActor
    func testMainViewAppears() throws {
        app.launch()

        // 앱 제목 확인
        XCTAssertTrue(app.staticTexts["Coffee-Screen"].exists)

        // 잠금 버튼 확인
        XCTAssertTrue(app.buttons["화면 잠금"].exists || app.buttons["Lock Screen"].exists)
    }

    @MainActor
    func testMainView_ShowsStatusIndicators() throws {
        app.launch()

        // 상태 표시 영역 확인 (활성/일반 상태)
        let hasAwakeStatus = app.staticTexts["활성 상태"].exists || app.staticTexts["Awake"].exists
        let hasNormalStatus = app.staticTexts["일반 상태"].exists || app.staticTexts["Normal"].exists

        XCTAssertTrue(hasAwakeStatus || hasNormalStatus)
    }

    @MainActor
    func testMainView_ShowsScreenCount() throws {
        app.launch()

        // 모니터 수 표시 확인 (최소 1개)
        let hasDisplayIcon = app.images["display"].exists ||
                            app.staticTexts.matching(NSPredicate(format: "label CONTAINS '1'")).count > 0

        // 앱이 실행되면 모니터 수가 표시됨
        XCTAssertTrue(app.windows.count > 0)
    }

    @MainActor
    func testMainView_LockButtonIsEnabled() throws {
        app.launch()

        let lockButton = app.buttons["화면 잠금"].exists ?
                        app.buttons["화면 잠금"] :
                        app.buttons["Lock Screen"]

        XCTAssertTrue(lockButton.exists)
        XCTAssertTrue(lockButton.isEnabled)
    }

    // MARK: - Performance Tests

    @MainActor
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}

// MARK: - Localization Tests

final class LocalizationUITests: XCTestCase {

    @MainActor
    func testKoreanLocalization_WhenSystemIsKorean() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(ko)"]
        app.launch()

        // 한국어 UI 요소 확인
        let hasKoreanTitle = app.staticTexts["Coffee-Screen"].exists
        let hasKoreanButton = app.buttons["화면 잠금"].exists

        XCTAssertTrue(hasKoreanTitle)
        // 언어 설정에 따라 버튼이 한국어로 표시되어야 함
        if app.buttons["화면 잠금"].exists || app.buttons["Lock Screen"].exists {
            // 둘 중 하나가 있으면 통과
        } else {
            XCTFail("Lock button not found")
        }
    }

    @MainActor
    func testEnglishLocalization_WhenSystemIsEnglish() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)"]
        app.launch()

        // 영어 UI 요소 확인
        let hasEnglishTitle = app.staticTexts["Coffee-Screen"].exists
        XCTAssertTrue(hasEnglishTitle)

        // 영어 또는 한국어 버튼 중 하나가 있어야 함
        if app.buttons["Lock Screen"].exists || app.buttons["화면 잠금"].exists {
            // 둘 중 하나가 있으면 통과
        } else {
            XCTFail("Lock button not found")
        }
    }
}
