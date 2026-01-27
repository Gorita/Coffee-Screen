# 아키텍처 설계

## 개요

Coffee-Screen은 **MVVM (Model-View-ViewModel)** 패턴을 기반으로 설계됩니다.
SwiftUI와의 자연스러운 통합과 테스트 용이성을 위해 이 패턴을 선택했습니다.

## 전체 아키텍처

```
┌────────────────────────────────────────────────────────────────┐
│                         Application                             │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    CoffeeScreenApp                        │  │
│  │                   (앱 진입점, 생명주기)                     │  │
│  └──────────────────────────────────────────────────────────┘  │
├────────────────────────────────────────────────────────────────┤
│                         Presentation                            │
│  ┌────────────┐  ┌────────────┐  ┌────────────────────────┐   │
│  │  MainView  │  │ ShieldView │  │      UnlockView        │   │
│  └─────┬──────┘  └─────┬──────┘  └───────────┬────────────┘   │
│        │               │                      │                │
│        ▼               ▼                      ▼                │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │                    ViewModels                            │  │
│  │  ┌─────────────────┐      ┌─────────────────────────┐   │  │
│  │  │  MainViewModel  │      │    ShieldViewModel      │   │  │
│  │  └─────────────────┘      └─────────────────────────┘   │  │
│  └─────────────────────────────────────────────────────────┘  │
├────────────────────────────────────────────────────────────────┤
│                          Domain                                 │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │                       AppState                           │  │
│  │  (isLocked, isAwake, authenticationError, etc.)          │  │
│  └─────────────────────────────────────────────────────────┘  │
├────────────────────────────────────────────────────────────────┤
│                        Infrastructure                           │
│  ┌─────────────┐ ┌─────────────┐ ┌──────────────────────┐     │
│  │   Power     │ │   Kiosk     │ │   ShieldWindow       │     │
│  │ Controller  │ │  Enforcer   │ │    Controller        │     │
│  └─────────────┘ └─────────────┘ └──────────────────────┘     │
│  ┌─────────────┐ ┌─────────────┐ ┌──────────────────────┐     │
│  │    Auth     │ │    PIN      │ │  KeyCombination      │     │
│  │   Manager   │ │   Manager   │ │     Manager          │     │
│  └─────────────┘ └─────────────┘ └──────────────────────┘     │
│  ┌─────────────────────┐ ┌─────────────────────────────────┐  │
│  │  StatusBarController│ │         NotificationService     │  │
│  └─────────────────────┘ └─────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────┘
```

## 레이어 설명

### 1. Application Layer
앱의 진입점과 생명주기를 관리합니다.

```swift
@main
struct CoffeeScreenApp: App {
    @StateObject private var mainViewModel = MainViewModel()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(mainViewModel)
        }
    }
}
```

### 2. Presentation Layer (Views)

#### MainView
- 앱의 메인 설정 화면
- 잠금 시작/설정 UI 제공

#### ShieldView
- 화면을 덮는 검은 오버레이
- 중앙에 UnlockView 표시

#### UnlockView
- 잠금 해제 버튼 및 인증 UI
- 인증 실패 시 에러 메시지 표시

### 3. ViewModel Layer

#### MainViewModel
```swift
class MainViewModel: ObservableObject {
    @Published var appState: AppState

    private let powerController: PowerController
    private let kioskEnforcer: KioskEnforcer
    private let shieldWindowController: ShieldWindowController

    func startLock() { }
    func stopLock() { }
}
```

#### ShieldViewModel
```swift
class ShieldViewModel: ObservableObject {
    @Published var isAuthenticating: Bool
    @Published var authError: String?

    private let authManager: AuthManager

    func attemptUnlock() { }
}
```

### 4. Domain Layer (Models)

#### AppState
```swift
struct AppState {
    var isLocked: Bool           // 화면 잠금 상태
    var isAwake: Bool            // 수면 방지 활성화 상태
    var isPowerConnected: Bool   // 전원 연결 상태
    var connectedScreens: Int    // 연결된 모니터 수
}
```

### 5. Infrastructure Layer (Controllers/Services)

#### PowerController
- IOKit 전원 관리 담당
- Power Assertion 생성/해제

#### KioskEnforcer
- NSApplication.presentationOptions 관리
- 키오스크 모드 진입/해제

#### ShieldWindowController
- 다중 모니터 감지
- 각 모니터별 ShieldWindow 생성/관리

#### AuthManager
- LocalAuthentication 처리
- Touch ID / 비밀번호 인증

#### NotificationService
- 전원 연결 상태 변화 알림
- 모니터 연결/해제 알림

## 모듈 상세 설계

### PowerController

```swift
class PowerController {
    private var assertionID: IOPMAssertionID = 0
    private(set) var isActive: Bool = false

    /// 시스템 수면 방지 시작
    func startAwake() -> Result<Void, PowerError>

    /// 시스템 수면 방지 해제
    func stopAwake() -> Result<Void, PowerError>
}

enum PowerError: Error {
    case assertionCreationFailed
    case assertionReleaseFailed
}
```

### KioskEnforcer

```swift
class KioskEnforcer {
    private var previousOptions: NSApplication.PresentationOptions = []
    private(set) var isLocked: Bool = false

    /// 키오스크 모드 활성화
    func lockUI()

    /// 키오스크 모드 해제
    func unlockUI()
}
```

### ShieldWindowController

```swift
class ShieldWindowController {
    private var shieldWindows: [NSWindow] = []

    /// 모든 모니터에 Shield Window 생성
    func showShields(with viewModel: ShieldViewModel)

    /// 모든 Shield Window 닫기
    func hideShields()

    /// 모니터 변경 감지 및 대응
    func handleScreenChange()
}
```

### AuthManager

```swift
class AuthManager {
    /// 생체 인증 또는 비밀번호 인증 시도
    func authenticate(reason: String) async -> Result<Bool, AuthError>
}

enum AuthError: Error {
    case cancelled
    case failed(String)
    case notAvailable
}
```

### PINManager

```swift
final class PINManager {
    static let shared: PINManager

    /// PIN 설정 여부
    var isPINSet: Bool

    /// PIN 설정 (4-8자리 숫자)
    func setPIN(_ pin: String) -> Bool

    /// PIN 검증
    func verifyPIN(_ pin: String) -> Bool

    /// PIN 삭제
    func deletePIN() -> Bool
}
```

### KeyCombinationManager

```swift
final class KeyCombinationManager {
    static let shared: KeyCombinationManager

    /// 현재 설정된 비상 탈출 키 조합
    var currentKeyCombination: KeyCombination

    /// 커스텀 키 설정
    func setKeyCombination(_ combination: KeyCombination) -> Bool

    /// 기본값으로 복원
    func resetToDefault()
}
```

### StatusBarController

```swift
final class StatusBarController: NSObject, NSMenuDelegate {
    /// 상태 업데이트 (잠금 상태, PIN 설정 여부)
    func updateStatus(isLocked: Bool, isPINSet: Bool)

    /// 잠금/해제 토글 콜백
    var onLockToggle: (() -> Void)?

    /// PIN 설정 화면 열기 콜백
    var onOpenPINSettings: (() -> Void)?
}
```

## 데이터 흐름

### 잠금 시작 플로우

```
[사용자: 잠금 버튼 클릭]
           │
           ▼
    ┌──────────────┐
    │  MainView    │
    │ onLockTapped │
    └──────┬───────┘
           │
           ▼
    ┌──────────────────┐
    │  MainViewModel   │
    │   startLock()    │
    └──────┬───────────┘
           │
           ├──────────────────────────────────────┐
           │                                      │
           ▼                                      ▼
    ┌──────────────────┐               ┌──────────────────┐
    │ PowerController  │               │  KioskEnforcer   │
    │   startAwake()   │               │    lockUI()      │
    └──────────────────┘               └──────────────────┘
           │                                      │
           └──────────────────────────────────────┤
                                                  │
                                                  ▼
                                    ┌─────────────────────────┐
                                    │ ShieldWindowController  │
                                    │     showShields()       │
                                    └─────────────────────────┘
                                                  │
                                                  ▼
                                    ┌─────────────────────────┐
                                    │   ShieldWindow(s)       │
                                    │   + UnlockView          │
                                    └─────────────────────────┘
```

### 잠금 해제 플로우

```
[사용자: 잠금 해제 버튼 클릭]
           │
           ▼
    ┌──────────────┐
    │  UnlockView  │
    │ onUnlockTap  │
    └──────┬───────┘
           │
           ▼
    ┌──────────────────┐
    │  ShieldViewModel │
    │ attemptUnlock()  │
    └──────┬───────────┘
           │
           ▼
    ┌──────────────────┐
    │   AuthManager    │
    │  authenticate()  │
    └──────┬───────────┘
           │
           ├── 실패 ──▶ [에러 메시지 표시]
           │
           ▼ 성공
    ┌──────────────────┐
    │  MainViewModel   │
    │   stopLock()     │
    └──────┬───────────┘
           │
           ├──────────────────────────────────────┐
           ▼                                      ▼
    ┌──────────────────┐               ┌──────────────────┐
    │ PowerController  │               │  KioskEnforcer   │
    │   stopAwake()    │               │   unlockUI()     │
    └──────────────────┘               └──────────────────┘
           │                                      │
           └──────────────────────────────────────┤
                                                  ▼
                                    ┌─────────────────────────┐
                                    │ ShieldWindowController  │
                                    │     hideShields()       │
                                    └─────────────────────────┘
```

## 상태 관리

### AppState 구조

```swift
class AppState: ObservableObject {
    @Published var isLocked: Bool = false
    @Published var isAwake: Bool = false
    @Published var isPowerConnected: Bool = true
    @Published var connectedScreens: Int = 1
    @Published var lastError: AppError?
}
```

### 상태 전이 다이어그램

```
                    ┌─────────────────┐
                    │     Idle        │
                    │  (isLocked=F)   │
                    └────────┬────────┘
                             │
                    [startLock() 호출]
                             │
                             ▼
                    ┌─────────────────┐
                    │   Activating    │
                    │ (Power+Kiosk)   │
                    └────────┬────────┘
                             │
                    [모든 활성화 완료]
                             │
                             ▼
                    ┌─────────────────┐
          ┌────────│    Locked       │────────┐
          │        │  (isLocked=T)   │        │
          │        └────────┬────────┘        │
          │                 │                 │
    [인증 실패]        [인증 성공]       [비상 키]
          │                 │                 │
          │                 ▼                 │
          │        ┌─────────────────┐        │
          │        │  Deactivating   │        │
          │        │ (Power+Kiosk)   │        │
          │        └────────┬────────┘        │
          │                 │                 │
          │        [모든 비활성화 완료]        │
          │                 │                 │
          │                 ▼                 │
          │        ┌─────────────────┐        │
          └───────▶│     Idle        │◀───────┘
                   │  (isLocked=F)   │
                   └─────────────────┘
```

## 에러 처리 전략

### 에러 타입 정의

```swift
enum AppError: Error {
    case powerAssertionFailed
    case kioskModeFailed
    case authenticationFailed(String)
    case screenDetectionFailed
}
```

### 에러 복구 전략

| 에러 | 복구 방법 |
|------|----------|
| Power Assertion 실패 | 사용자에게 경고 표시, 잠금 계속 진행 |
| Kiosk Mode 실패 | 잠금 취소, 에러 메시지 표시 |
| 인증 실패 | 재시도 허용, 에러 메시지 표시 |
| 화면 감지 실패 | 기본 화면에만 Shield 표시 |

## 비상 탈출 메커니즘

### 사용자 설정 가능한 단축키

비상 탈출 키는 사용자가 설정할 수 있으며, 기본값은 "양쪽 Shift + Cmd + L"입니다.

```swift
// KeyCombinationManager가 현재 설정된 키 조합을 관리
// KeyCombination 모델이 키 조합 데이터를 저장

func setupEmergencyEscape() {
    NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
        let currentCombination = KeyCombinationManager.shared.currentKeyCombination
        if isEmergencyKeyCombo(event, combination: currentCombination) {
            emergencyUnlock()
            return nil
        }
        return event
    }
}
```

### 키 조합 요구사항
- 최소 Cmd 또는 Ctrl 키 포함 필수 (실수로 트리거 방지)
- 양쪽 Shift 키 동시 누름 지원
- UserDefaults에 설정 저장

### 타임아웃

- 인증 5회 연속 실패 시 30초 대기 후 재시도 허용
- 앱 응답 없음 10초 이상 지속 시 자동 잠금 해제 (선택적)

## UI Components

### 디자인 시스템

Coffee-Screen은 8-bit 레트로 스타일의 커피 테마 디자인을 사용합니다.

#### 폰트
- **Silkscreen-Regular**: 메인 UI 폰트 (픽셀 스타일)
- Press Start 2P, VT323: 대체 폰트 (번들에 포함)

#### 컬러 팔레트
```swift
extension Color {
    static let coffeeBrown = Color(red: 0.44, green: 0.26, blue: 0.13)  // 메인 브라운
    static let coffeeCream = Color(red: 0.96, green: 0.93, blue: 0.88)  // 밝은 크림
    static let coffeeLight = Color(red: 0.85, green: 0.75, blue: 0.62)  // 라이트 브라운
    static let coffeeDark = Color(red: 0.30, green: 0.18, blue: 0.10)   // 다크 브라운
}
```

### PixelShape

8-bit 스타일의 모서리를 가진 커스텀 Shape입니다.

```swift
struct PixelShape: Shape {
    var cornerSize: CGFloat = 4  // 모서리 노치 크기
    // 각 모서리에 계단식 노치가 있는 Shape
}
```

### PixelButtonStyle

레트로 게임 스타일의 버튼:
- **PixelButtonStyle**: Primary 버튼 (커피 브라운)
- **PixelButtonStyleSecondary**: Secondary 버튼 (크림색)
- **PixelButtonStyleLarge**: 큰 버튼 (Lock Screen용)
- **pixelDestructive**: 삭제 버튼 (빨간색)

```
    ┌──────────┐
   ╱            ╲    <- 픽셀 스타일 모서리
  │   BUTTON    │
   ╲            ╱
    └──────────┘
```

## 테스트 전략

### 단위 테스트 대상

| 모듈 | 테스트 항목 |
|------|------------|
| PowerController | Assertion 생성/해제 |
| KioskEnforcer | PresentationOptions 설정/해제 |
| AuthManager | 인증 성공/실패/취소 |
| MainViewModel | 상태 전이 로직 |
| ShieldViewModel | 인증 플로우 |

### 통합 테스트 시나리오

1. 전체 잠금 → 인증 → 해제 플로우
2. 다중 모니터 환경 Shield 표시
3. 모니터 연결/해제 시 동적 대응

### UI 테스트 시나리오

1. 메인 화면 → 잠금 버튼 → Shield 표시 확인
2. Shield 화면 → 잠금 해제 버튼 → 인증 다이얼로그
