import Foundation

/// 앱의 전역 상태를 관리하는 모델
struct AppState {
    /// 화면 잠금 상태
    var isLocked: Bool = false

    /// 수면 방지 활성화 상태
    var isAwake: Bool = false

    /// 전원 연결 상태
    var isPowerConnected: Bool = true

    /// 연결된 모니터 수
    var connectedScreens: Int = 1

    /// 마지막 에러 메시지
    var lastError: String?
}
