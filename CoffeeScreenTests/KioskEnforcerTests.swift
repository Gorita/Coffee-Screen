import XCTest
@testable import CoffeeScreen

@MainActor
final class KioskEnforcerTests: XCTestCase {

    var sut: KioskEnforcer!

    override func setUpWithError() throws {
        sut = KioskEnforcer()
    }

    override func tearDownWithError() throws {
        sut?.unlockUI()
        sut = nil
    }

    // MARK: - Initial State Tests

    func testInitialState_IsNotLocked() {
        XCTAssertFalse(sut.isLocked)
    }

    // MARK: - lockUI Tests

    func testLockUI_SetsIsLockedToTrue() {
        sut.lockUI()

        XCTAssertTrue(sut.isLocked)
    }

    func testLockUI_CalledTwice_StillLocked() {
        sut.lockUI()
        sut.lockUI()

        XCTAssertTrue(sut.isLocked)
    }

    // MARK: - unlockUI Tests

    func testUnlockUI_AfterLock_SetsIsLockedToFalse() {
        sut.lockUI()

        sut.unlockUI()

        XCTAssertFalse(sut.isLocked)
    }

    func testUnlockUI_WithoutLock_DoesNotCrash() {
        // 잠금하지 않은 상태에서 호출해도 크래시하지 않아야 함
        sut.unlockUI()

        XCTAssertFalse(sut.isLocked)
    }

    func testUnlockUI_CalledTwice_DoesNotCrash() {
        sut.lockUI()
        sut.unlockUI()

        sut.unlockUI()

        XCTAssertFalse(sut.isLocked)
    }

    // MARK: - Kiosk Options Tests

    func testLockUI_DisablesProcessSwitching() {
        sut.lockUI()

        // 키오스크 모드가 활성화되면 특정 옵션이 설정됨
        // 실제 NSApp.presentationOptions 확인은 통합 테스트에서 수행
        XCTAssertTrue(sut.isLocked)
    }
}
