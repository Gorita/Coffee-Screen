# 구현 계획

## 개요

이 문서는 Coffee-Screen 애플리케이션의 단계별 구현 계획을 정의합니다.
각 단계는 독립적으로 테스트 가능하며, 이전 단계의 완료를 전제로 합니다.

## 구현 단계

```
Phase 1: 프로젝트 설정 및 기본 구조
    │
    ▼
Phase 2: 핵심 인프라 구현 (Controllers)
    │
    ▼
Phase 3: 화면 가림 기능 구현
    │
    ▼
Phase 4: 인증 시스템 구현
    │
    ▼
Phase 5: UI 구현 및 통합
    │
    ▼
Phase 6: 테스트 및 안정화
    │
    ▼
Phase 7: 배포 준비
```

---

## Phase 1: 프로젝트 설정 및 기본 구조

### 목표
Xcode 프로젝트 생성 및 기본 폴더 구조 설정

### 작업 항목

#### 1.1 Xcode 프로젝트 생성
- [x] 새 macOS App 프로젝트 생성 (XcodeGen 사용)
- [x] Bundle Identifier: `com.gorita.coffee-screen`
- [x] Deployment Target: macOS 14.0
- [x] Interface: SwiftUI
- [x] Language: Swift

#### 1.2 폴더 구조 생성
```
CoffeeScreen/
├── App/
├── Models/
├── ViewModels/
├── Views/
├── Controllers/
├── Services/
├── Utilities/
└── Resources/
```
- [x] 완료

#### 1.3 기본 설정
- [x] Info.plist 설정
  - LSUIElement: NO (Dock에 표시)
  - NSPrincipalClass: NSApplication
- [x] Localizable.xcstrings 생성 (한국어, 영어)
- [x] Assets.xcassets 앱 아이콘 구조 추가

#### 1.4 Constants 정의
```swift
// Utilities/Constants.swift
enum Constants {
    static let appName = "Coffee-Screen"
    static let emergencyKeyCombo = "Shift+Shift+Cmd+L"
    static let shieldWindowLevel = 1001
}
```

### 완료 기준
- [x] 프로젝트가 빌드되고 빈 화면이 표시됨
- [x] 폴더 구조가 올바르게 설정됨

---

## Phase 2: 핵심 인프라 구현

### 목표
PowerController, KioskEnforcer 구현

### 작업 항목

#### 2.1 PowerController 구현
```swift
// Controllers/PowerController.swift
import IOKit.pwr_mgt

class PowerController {
    private var assertionID: IOPMAssertionID = 0

    func startAwake() -> Bool {
        let reason = "Coffee-Screen: Long running task" as CFString
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypeNoIdleSleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason,
            &assertionID
        )
        return result == kIOReturnSuccess
    }

    func stopAwake() {
        if assertionID != 0 {
            IOPMAssertionRelease(assertionID)
            assertionID = 0
        }
    }
}
```

#### 2.2 KioskEnforcer 구현
```swift
// Controllers/KioskEnforcer.swift
import AppKit

class KioskEnforcer {
    private var previousOptions: NSApplication.PresentationOptions = []

    func lockUI() {
        previousOptions = NSApp.presentationOptions

        let kioskOptions: NSApplication.PresentationOptions = [
            .disableForceQuit,
            .disableProcessSwitching,
            .disableSessionTermination,
            .disableAppleMenu,
            .disableHideApplication,
            .hideDock,
            .hideMenuBar
        ]

        NSApp.presentationOptions = kioskOptions
        NSCursor.hide()
    }

    func unlockUI() {
        NSApp.presentationOptions = previousOptions
        NSCursor.unhide()
    }
}
```

#### 2.3 단위 테스트 작성
- [x] PowerControllerTests (7개 테스트)
- [x] KioskEnforcerTests (7개 테스트)

### 완료 기준
- [x] PowerController가 시스템 수면을 방지함 (IOKit Power Assertion)
- [x] KioskEnforcer가 Cmd+Tab, Cmd+Opt+Esc를 차단함 (NSApplication.PresentationOptions)
- [x] MainViewModel에 Controller 통합 완료

---

## Phase 3: 화면 가림 기능 구현

### 목표
ShieldWindow, ShieldWindowController 구현

### 작업 항목

#### 3.1 ShieldWindow 구현
```swift
// Controllers/ShieldWindow.swift
import AppKit
import SwiftUI

class ShieldWindow: NSWindow {
    init(screen: NSScreen, content: some View) {
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        self.level = NSWindow.Level(rawValue: Constants.shieldWindowLevel)
        self.backgroundColor = .black
        self.isOpaque = true
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.contentView = NSHostingView(rootView: content)
    }
}
```

#### 3.2 ShieldWindowController 구현
```swift
// Controllers/ShieldWindowController.swift
class ShieldWindowController {
    private var shieldWindows: [ShieldWindow] = []

    func showShields(with viewModel: ShieldViewModel) {
        for screen in NSScreen.screens {
            let window = ShieldWindow(
                screen: screen,
                content: ShieldView(viewModel: viewModel)
            )
            window.makeKeyAndOrderFront(nil)
            shieldWindows.append(window)
        }
    }

    func hideShields() {
        shieldWindows.forEach { $0.close() }
        shieldWindows.removeAll()
    }
}
```

#### 3.3 모니터 변경 감지
```swift
// 모니터 연결/해제 시 Shield 재생성
NotificationCenter.default.addObserver(
    forName: NSApplication.didChangeScreenParametersNotification,
    object: nil,
    queue: .main
) { _ in
    self.handleScreenChange()
}
```

### 완료 기준
- [x] 모든 모니터가 검은 화면으로 덮임 (ShieldWindow, screenSaverWindow+1 레벨)
- [x] 다른 윈도우가 Shield 위에 표시되지 않음 (canJoinAllSpaces)
- [x] 모니터 연결/해제 시 Shield가 동적으로 대응 (didChangeScreenParametersNotification)
- [x] ShieldView, UnlockView UI 구현
- [x] ShieldViewModel 구현
- [x] MainViewModel에 ShieldWindowController 통합

---

## Phase 4: 인증 시스템 구현

### 목표
AuthManager 및 인증 UI 구현

### 작업 항목

#### 4.1 AuthManager 구현
```swift
// Controllers/AuthManager.swift
import LocalAuthentication

class AuthManager {
    func authenticate(reason: String) async -> Result<Bool, AuthError> {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            return .failure(.notAvailable)
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )
            return .success(success)
        } catch let error as LAError {
            switch error.code {
            case .userCancel:
                return .failure(.cancelled)
            default:
                return .failure(.failed(error.localizedDescription))
            }
        }
    }
}

enum AuthError: Error {
    case cancelled
    case failed(String)
    case notAvailable
}
```

#### 4.2 비상 탈출 키 구현
```swift
// 숨겨진 단축키: 양쪽 Shift + Cmd + L
func setupEmergencyEscape(onEscape: @escaping () -> Void) {
    NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
        // Cmd + L 키이고, 양쪽 Shift 모두 눌린 상태
        if event.modifierFlags.contains([.command, .shift]) &&
           event.keyCode == 0x25 /* L */ {
            onEscape()
            return nil
        }
        return event
    }
}
```

### 완료 기준
- [x] Touch ID 인증이 작동함 (AuthManager + LAContext)
- [x] Touch ID 실패 시 비밀번호 입력으로 폴백 (deviceOwnerAuthentication 정책)
- [x] 비상 탈출 키가 작동함 (EmergencyEscapeHandler)
- [x] 비상 탈출 키 설정 가능 (KeyCombinationManager, 기본값: 양쪽 Shift + Cmd + L)
- [x] PIN 기반 잠금 해제 지원 (PINManager)
- [x] AuthManager 테스트 (7개)
- [x] EmergencyEscapeHandler 테스트 (12개)
- [x] ShieldViewModel 통합 테스트 (12개)
- [x] KeyCombinationTests (18개)
- [x] KeyCombinationManagerTests (9개)

---

## Phase 5: UI 구현 및 통합

### 목표
SwiftUI 뷰 및 ViewModel 구현, 전체 통합

### 작업 항목

#### 5.1 Models
```swift
// Models/AppState.swift
class AppState: ObservableObject {
    @Published var isLocked: Bool = false
    @Published var isAwake: Bool = false
    @Published var isPowerConnected: Bool = true
}
```

#### 5.2 ViewModels
```swift
// ViewModels/MainViewModel.swift
class MainViewModel: ObservableObject {
    @Published var appState = AppState()

    private let powerController = PowerController()
    private let kioskEnforcer = KioskEnforcer()
    private let shieldWindowController = ShieldWindowController()

    func startLock() { }
    func stopLock() { }
}

// ViewModels/ShieldViewModel.swift
class ShieldViewModel: ObservableObject {
    @Published var isAuthenticating = false
    @Published var authError: String?

    private let authManager = AuthManager()
    var onUnlockSuccess: (() -> Void)?

    func attemptUnlock() { }
}
```

#### 5.3 Views
```swift
// Views/MainView.swift
struct MainView: View {
    @StateObject private var viewModel = MainViewModel()

    var body: some View {
        VStack {
            // 상태 표시
            // 잠금 버튼
            // 설정 옵션
        }
    }
}

// Views/ShieldView.swift
struct ShieldView: View {
    @ObservedObject var viewModel: ShieldViewModel

    var body: some View {
        ZStack {
            Color.black
            UnlockView(viewModel: viewModel)
        }
    }
}

// Views/UnlockView.swift
struct UnlockView: View {
    @ObservedObject var viewModel: ShieldViewModel

    var body: some View {
        VStack {
            // 잠금 아이콘
            // 잠금 해제 버튼
            // 에러 메시지
        }
    }
}
```

#### 5.4 Localization
```
// Localizable.xcstrings
"lock.button" = "화면 잠금"
"unlock.button" = "잠금 해제"
"unlock.reason" = "잠금을 해제하려면 인증하세요"
"error.auth.failed" = "인증에 실패했습니다"
"warning.power" = "전원 어댑터를 연결하세요"
```

### 완료 기준
- [x] 메인 화면이 올바르게 표시됨 (UI 테스트 검증)
- [x] 잠금 → Shield 표시 → 인증 → 해제 플로우가 작동
- [x] 다국어(한국어/영어)가 올바르게 표시됨 (Localization UI 테스트)
- [x] UI 테스트 추가 (7개)

---

## Phase 6: 테스트 및 안정화

### 목표
전체 테스트 커버리지 확보 및 버그 수정

### 작업 항목

#### 6.1 Unit Tests (82개)
- [x] PowerControllerTests (7개)
- [x] KioskEnforcerTests (7개)
- [x] AuthManagerTests (3개)
- [x] AuthErrorTests (4개)
- [x] EmergencyEscapeHandlerTests (12개)
- [x] ShieldViewModelTests (9개)
- [x] ShieldViewModelWithMockTests (3개)
- [x] ShieldWindowControllerTests (3개)
- [x] ShieldWindowTests (4개)
- [x] MainViewModelTests (3개)
- [x] KeyCombinationTests (18개)
- [x] KeyCombinationManagerTests (9개)

#### 6.2 UI Tests (7개)
- [x] MainView 표시 테스트
- [x] 상태 표시 테스트
- [x] 잠금 버튼 테스트
- [x] 한국어 로컬라이제이션 테스트
- [x] 영어 로컬라이제이션 테스트
- [x] 앱 실행 성능 테스트

> 참고: 전체 잠금/해제 플로우, 인증 실패 시나리오, 비상 탈출 키 테스트는
> 키오스크 모드와 시스템 인증이 필요하여 자동화 테스트 불가 (수동 테스트 필요)

#### 6.3 수동 테스트 체크리스트
- [ ] 다중 모니터 환경 테스트
- [ ] 모니터 연결/해제 테스트
- [ ] 장시간 실행 테스트 (수면 방지 확인)
- [ ] Clamshell 모드 테스트
- [ ] 전체 잠금/해제 플로우 테스트
- [ ] Touch ID 인증 테스트
- [ ] PIN 인증 테스트
- [ ] 비밀번호 폴백 테스트
- [ ] 비상 탈출 키 테스트 (기본값: 양쪽 Shift + Cmd + L)
- [ ] 비상 탈출 키 변경 및 저장 테스트
- [ ] 상태바 메뉴 테스트 (PIN 미설정 시 잠금 비활성화)

#### 6.4 엣지 케이스 (수동 테스트)
- [ ] Touch ID 5회 연속 실패 → 비밀번호 입력
- [ ] 인증 중 모니터 해제 → Shield 재생성
- [ ] 잠금 중 앱 강제 종료 시도 → Kiosk Mode가 차단

### 완료 기준
- [x] Unit Test 82개 통과
- [x] 모든 자동화 테스트 통과
- [ ] 수동 테스트 완료
- [ ] 알려진 버그 없음

---

## Phase 7: 배포 준비

### 목표
앱 서명, 공증, 배포 패키지 생성

### 작업 항목

#### 7.1 코드 서명
- [x] Developer ID Application 인증서 설정 (project.yml Release config)
- [x] Team ID 설정 (환경변수 DEVELOPMENT_TEAM)
- [x] Hardened Runtime 활성화 (Release config에서 YES)

#### 7.2 Notarization
- [x] 빌드 스크립트 생성 (scripts/build.sh)
- [x] 공증 스크립트 생성 (scripts/notarize.sh)
- [x] ExportOptions.plist 생성
- [x] 환경변수 템플릿 생성 (.env.template)

```bash
# 빌드 및 공증 실행
source .env && ./scripts/build.sh --notarize
```

#### 7.3 배포 패키지
- [x] DMG 생성 스크립트 (scripts/create-dmg.sh)
- [x] 전체 릴리스 스크립트 (scripts/release.sh)
- [x] 배포 가이드 문서 (docs/DEPLOYMENT.md)
- [ ] GitHub Release 생성 (수동 실행 필요)

### 완료 기준
- [x] 빌드/서명/공증 스크립트 완성
- [ ] 실제 인증서로 서명 테스트
- [ ] Gatekeeper 경고 없이 실행 확인
- [ ] DMG 설치 테스트

---

## 일정 (참고용)

| Phase | 설명 | 의존성 |
|-------|------|--------|
| 1 | 프로젝트 설정 | - |
| 2 | 핵심 인프라 | Phase 1 |
| 3 | 화면 가림 | Phase 1 |
| 4 | 인증 시스템 | Phase 1 |
| 5 | UI 통합 | Phase 2, 3, 4 |
| 6 | 테스트 | Phase 5 |
| 7 | 배포 | Phase 6 |

> **참고**: Phase 2, 3, 4는 병렬로 진행 가능

---

## 위험 요소 및 대응

| 위험 | 영향 | 대응 |
|------|------|------|
| Kiosk Mode API 변경 | 높음 | Apple 문서 지속 모니터링, 대체 방법 연구 |
| 보안 프로그램 충돌 | 중간 | 테스트 환경에서 사전 검증 |
| 인증 모듈 오작동 | 높음 | 비상 탈출 키 필수 구현 |
| 다중 모니터 엣지 케이스 | 중간 | 충분한 테스트 케이스 확보 |

---

## 체크리스트 요약

### 필수 기능
- [ ] 시스템 수면 방지
- [ ] 화면 가림 (다중 모니터)
- [ ] 키오스크 모드
- [ ] Touch ID / 비밀번호 인증
- [ ] 비상 탈출 키

### 품질 요구사항
- [ ] Unit Test 커버리지 80%
- [ ] UI Test 통과
- [ ] 다국어 지원 (한/영)
- [ ] 코드 서명 및 공증
