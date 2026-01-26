# Coffee-Screen 프로젝트 가이드

## 프로젝트 개요

Coffee-Screen은 macOS용 **장기 실행 프로세스 보장 및 화면 보안 애플리케이션**입니다.
AI 학습, 대용량 렌더링 등 장시간 작업 시 시스템 수면을 방지하고, 화면을 가려 작업 내용을 보호합니다.

## 기술 스택

| 항목 | 선택 |
|------|------|
| 언어 | Swift |
| UI | SwiftUI |
| 최소 지원 버전 | macOS 14 (Sonoma) |
| 아키텍처 | MVVM |
| 배포 | Direct Distribution (Developer ID) |
| 테스트 | XCTest (Unit + UI) |
| 다국어 | 한국어, 영어 |

## 핵심 기능 (Features)

1. **Awake Maintenance** - IOKit Power Assertion으로 시스템 수면 방지
2. **Visual Shield** - 모든 모니터를 덮는 검은 윈도우로 화면 은폐
3. **Access Restriction** - Kiosk Mode API로 키보드/마우스 이탈 방지
4. **Secure Unlock** - Touch ID 또는 비밀번호로 잠금 해제

## 프로젝트 구조

```
Coffee-Screen/
├── CoffeeScreen/
│   ├── App/
│   │   └── CoffeeScreenApp.swift      # 앱 진입점, AppDelegate
│   ├── Models/
│   │   ├── AppState.swift             # 앱 상태 모델
│   │   └── KeyCombination.swift       # 키 조합 모델 (Codable)
│   ├── ViewModels/
│   │   ├── MainViewModel.swift        # 메인 뷰모델
│   │   ├── ShieldViewModel.swift      # 쉴드 뷰모델
│   │   ├── PINSettingsViewModel.swift # PIN 설정 뷰모델
│   │   └── KeyCombinationSettingsViewModel.swift # 비상 탈출 키 설정 뷰모델
│   ├── Views/
│   │   ├── MainView.swift             # 메인 설정 화면
│   │   ├── ShieldView.swift           # 화면 가림 뷰
│   │   ├── UnlockView.swift           # 잠금 해제 뷰
│   │   └── KeyRecorderView.swift      # 키 녹화 뷰 (NSViewRepresentable)
│   ├── Controllers/
│   │   ├── PowerController.swift      # IOKit 전원 관리
│   │   ├── KioskEnforcer.swift        # 키오스크 모드 제어
│   │   ├── ShieldWindowController.swift # 다중 모니터 윈도우 관리
│   │   ├── AuthManager.swift          # LocalAuthentication 처리
│   │   ├── PINManager.swift           # PIN 저장/검증 (UserDefaults)
│   │   ├── KeyCombinationManager.swift # 비상 탈출 키 저장/로드
│   │   ├── EmergencyEscapeHandler.swift # 비상 탈출 키 모니터링
│   │   └── StatusBarController.swift  # 메뉴바 상태 아이콘
│   ├── Services/
│   │   └── NotificationService.swift  # 알림 서비스
│   ├── Utilities/
│   │   └── Constants.swift            # 상수 정의
│   └── Resources/
│       ├── Localizable.xcstrings      # 다국어 문자열
│       └── Assets.xcassets            # 이미지 리소스
├── CoffeeScreenTests/                 # Unit Tests
├── CoffeeScreenUITests/               # UI Tests
└── docs/                              # 문서
```

## 핵심 모듈 설명

### PowerController
- `IOPMAssertionCreateWithName`으로 `kIOPMAssertionTypeNoIdleSleep` 생성
- CPU, Network 활성 상태 유지 (디스플레이 꺼짐은 허용)

### KioskEnforcer
- `NSApplication.PresentationOptions` 사용
- `.disableForceQuit`, `.disableProcessSwitching`, `.disableAppleMenu` 등 적용
- **Input Monitoring 권한 불필요**

### ShieldWindowController
- `NSScreen.screens`로 모든 모니터 감지
- `screenSaverWindow` 레벨 이상의 윈도우 생성
- `collectionBehavior = .canJoinAllSpaces`로 모든 Space에서 표시

### AuthManager
- `LAContext.evaluatePolicy(.deviceOwnerAuthentication)`
- Touch ID 실패 시 비밀번호 폴백

## 빌드 및 실행

```bash
# Xcode로 프로젝트 열기
open CoffeeScreen.xcodeproj

# 커맨드라인 빌드
xcodebuild -scheme CoffeeScreen -configuration Debug build

# 테스트 실행
xcodebuild test -scheme CoffeeScreen
```

## 작업 원칙

| 원칙 | 설명 |
|------|------|
| **TDD** | 테스트 코드 먼저 작성 → 실제 코드 구현 |
| **SOLID** | 간결하고 객체지향 원칙 준수 |
| **복잡성 최소화** | 구현 전 설계 고민 선행, 과도한 추상화 지양 |
| **TODO 리스트** | 작업 전 계획 수립, 진행 상황 추적 |
| **작업 완료 시** | TDD 완료 후 commit, 문서 업데이트 (진행 상황). 이슈 발생 시 사용자에게 질문 |

## 코딩 컨벤션

- Swift API Design Guidelines 준수
- MVVM 패턴: View는 ViewModel만 참조, ViewModel은 Model과 Controller 참조
- `@Published`, `@StateObject`, `@ObservedObject` 사용
- 에러 처리: Swift의 `Result` 타입 또는 `async/await` 사용
- 주석: 복잡한 로직에만 한국어로 작성

## 주의사항

- **하드웨어 전원 버튼 강제 종료는 막을 수 없음** (하드웨어 레벨 인터럽트)
- **Clamshell Mode**: 전원 미연결 시 덮개 닫으면 절전 진입 가능
- **비상 탈출**: 기본 Shift+Shift+Cmd+L, 설정에서 변경 가능 (Cmd 또는 Ctrl 필수)
- **기업 환경**: CGEventTap 사용 금지 (보안 프로그램 충돌)

## 관련 문서

- [기술 스택 상세](docs/TECH_STACK.md)
- [아키텍처 설계](docs/ARCHITECTURE.md)
- [구현 계획](docs/IMPLEMENTATION_PLAN.md)
