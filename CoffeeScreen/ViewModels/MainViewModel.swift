import Foundation
import SwiftUI

/// 메인 화면의 ViewModel
@MainActor
final class MainViewModel: ObservableObject {
    @Published var appState = AppState()

    /// 화면 잠금 시작
    func startLock() {
        // TODO: Phase 2에서 구현
        appState.isLocked = true
        appState.isAwake = true
    }

    /// 화면 잠금 해제
    func stopLock() {
        // TODO: Phase 2에서 구현
        appState.isLocked = false
        appState.isAwake = false
    }
}
