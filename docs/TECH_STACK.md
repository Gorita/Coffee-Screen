# 기술 스택 상세

## 개발 환경

| 항목 | 버전/도구 | 비고 |
|------|----------|------|
| IDE | Xcode 15+ | 최신 Swift 지원 |
| 언어 | Swift 5.9+ | Strict Concurrency 지원 |
| 최소 배포 타겟 | macOS 14.0 | Sonoma |
| 아키텍처 지원 | Universal (arm64, x86_64) | Apple Silicon + Intel |

## 프레임워크

### 핵심 프레임워크

| 프레임워크 | 용도 | 설명 |
|-----------|------|------|
| **SwiftUI** | UI | 선언적 UI 프레임워크 |
| **AppKit** | 윈도우 관리 | NSWindow, NSApplication 제어 |
| **IOKit** | 전원 관리 | Power Assertion 생성/해제 |
| **LocalAuthentication** | 인증 | Touch ID / 비밀번호 인증 |
| **CoreGraphics** | 화면 정보 | 모니터 정보, 윈도우 레벨 |

### 사용 API 상세

#### IOKit (전원 관리)
```swift
// 사용 함수
IOPMAssertionCreateWithName(_:_:_:_:)
IOPMAssertionRelease(_:)

// 사용 상수
kIOPMAssertionTypeNoIdleSleep  // CPU/Network 수면 방지
kIOPMAssertionLevelOn          // Assertion 활성화
```

#### AppKit (키오스크 모드)
```swift
// NSApplication.PresentationOptions
.disableForceQuit           // Cmd+Opt+Esc 비활성화
.disableProcessSwitching    // Cmd+Tab 비활성화
.disableSessionTermination  // 전원 버튼 메뉴 차단
.disableAppleMenu           // 애플 메뉴 차단
.disableHideApplication     // Cmd+H 차단
.hideDock                   // Dock 숨김
.hideMenuBar                // 메뉴바 숨김
```

#### CoreGraphics (윈도우 레벨)
```swift
// 윈도우 레벨 (낮음 → 높음)
CGWindowLevelForKey(.normalWindow)         // 1
CGWindowLevelForKey(.floatingWindow)       // 3
CGWindowLevelForKey(.mainMenuWindow)       // 24
CGWindowLevelForKey(.screenSaverWindow)    // 1000
// ShieldWindow는 1001 이상 사용
```

#### LocalAuthentication (인증)
```swift
// 인증 정책
LAPolicy.deviceOwnerAuthentication
// Touch ID 실패 시 자동으로 비밀번호 폴백

// 사용 클래스
LAContext
```

## UI 프레임워크 선택 근거

### SwiftUI 선택 이유
1. **선언적 UI**: 상태 변화에 따른 자동 UI 업데이트
2. **macOS 14 타겟**: 최신 SwiftUI 기능 모두 사용 가능
3. **MVVM 친화적**: `@Published`, `@StateObject` 등 상태 관리 용이
4. **빠른 개발**: 프리뷰 기능으로 즉시 확인 가능

### AppKit 병용
- `NSWindow` 레벨 제어 (SwiftUI에서 직접 불가)
- `NSApplication.presentationOptions` 설정
- `NSHostingView`로 SwiftUI 뷰를 NSWindow에 호스팅

## 아키텍처 패턴: MVVM

```
┌─────────────────────────────────────────────────────────┐
│                        View Layer                        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      │
│  │  MainView   │  │ ShieldView  │  │ UnlockView  │      │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘      │
└─────────┼────────────────┼────────────────┼─────────────┘
          │                │                │
          ▼                ▼                ▼
┌─────────────────────────────────────────────────────────┐
│                     ViewModel Layer                      │
│  ┌──────────────────────┐  ┌──────────────────────┐     │
│  │    MainViewModel     │  │   ShieldViewModel    │     │
│  │  @Published state    │  │  @Published state    │     │
│  └──────────┬───────────┘  └──────────┬───────────┘     │
└─────────────┼──────────────────────────┼────────────────┘
              │                          │
              ▼                          ▼
┌─────────────────────────────────────────────────────────┐
│                   Controller/Service Layer               │
│  ┌───────────────┐  ┌───────────────┐  ┌─────────────┐  │
│  │PowerController│  │ KioskEnforcer │  │ AuthManager │  │
│  └───────────────┘  └───────────────┘  └─────────────┘  │
│  ┌───────────────────────────────────────────────────┐  │
│  │            ShieldWindowController                 │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

## 테스트 전략

### Unit Test (XCTest)
- **대상**: ViewModel, Controller, Service
- **도구**: XCTest 프레임워크
- **커버리지 목표**: 핵심 로직 80% 이상

```swift
// 테스트 예시
class PowerControllerTests: XCTestCase {
    func testStartAwake_CreatesAssertion() { }
    func testStopAwake_ReleasesAssertion() { }
}
```

### UI Test (XCUITest)
- **대상**: 주요 사용자 플로우
- **시나리오**:
  1. 앱 실행 → 잠금 버튼 클릭 → 화면 가림 확인
  2. 잠금 상태 → 인증 → 잠금 해제 확인

## 빌드 및 배포

### 빌드 설정
```
Product Name: Coffee-Screen
Bundle Identifier: com.yourcompany.coffee-screen
Deployment Target: macOS 14.0
Architectures: Universal (arm64 + x86_64)
```

### 코드 서명
- **배포 방식**: Direct Distribution
- **서명**: Developer ID Application 인증서
- **Notarization**: Apple Notary Service를 통한 공증 필요

### 빌드 명령어
```bash
# 개발 빌드
xcodebuild -scheme CoffeeScreen -configuration Debug build

# 릴리스 빌드
xcodebuild -scheme CoffeeScreen -configuration Release build

# 아카이브 (배포용)
xcodebuild -scheme CoffeeScreen -configuration Release archive \
  -archivePath ./build/CoffeeScreen.xcarchive
```

## 의존성

### 외부 라이브러리
**없음** - 모든 기능을 Apple 기본 프레임워크로 구현

### 이유
1. **기업 환경 호환성**: 외부 라이브러리는 보안 심사 대상
2. **안정성**: Apple 공식 API만 사용하여 OS 업데이트 호환성 보장
3. **단순성**: 의존성 관리 부담 없음

## 권한 요구사항

| 권한 | 필요 여부 | 비고 |
|------|----------|------|
| 손쉬운 사용 | **불필요** | Kiosk Mode는 권한 불필요 |
| 입력 모니터링 | **불필요** | CGEventTap 미사용 |
| 화면 녹화 | **불필요** | 화면 캡처 기능 없음 |
| Touch ID | 자동 요청 | LocalAuthentication 사용 시 |

> **핵심 장점**: 민감한 권한을 요구하지 않아 기업 MDM 정책과 충돌하지 않음
