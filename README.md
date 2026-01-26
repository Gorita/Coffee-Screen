# Coffee-Screen

<p align="center">
  <img src="coffee-screen.png" alt="Coffee-Screen" width="600">
</p>

> macOS용 장기 실행 프로세스 보장 및 화면 보안 애플리케이션

## 소개

Coffee-Screen은 AI 학습, 대용량 데이터 렌더링 등 장시간 작업을 수행할 때 **시스템 수면을 방지**하고, **화면을 가려** 작업 내용을 보호하는 macOS 애플리케이션입니다.

기업 보안 환경(MDM, DLP, 백신 등)에서도 안전하게 동작하도록 설계되었습니다.

## 주요 기능

- **시스템 수면 방지**: IOKit Power Assertion으로 CPU, 네트워크 활성 상태 유지
- **화면 은폐**: 모든 모니터를 검은 윈도우로 덮어 작업 내용 보호
- **입력 차단**: Kiosk Mode API로 Cmd+Tab, 강제 종료 등 시스템 이탈 방지
- **안전한 잠금 해제**: Touch ID 또는 비밀번호로 인증

## 시스템 요구사항

- macOS 14 (Sonoma) 이상
- Apple Silicon 또는 Intel Mac

## 설치

### Direct Download
[Releases](https://github.com/Gorita/Coffee-Screen/releases) 페이지에서 최신 버전을 다운로드하세요.

### 빌드
```bash
git clone https://github.com/Gorita/Coffee-Screen.git
cd coffee-screen
open CoffeeScreen.xcodeproj
```

## 사용법

1. 앱을 실행합니다.
2. **"화면 잠금"** 버튼을 클릭합니다.
3. 화면이 검게 덮이고 시스템 수면이 방지됩니다.
4. 잠금 해제: 화면을 클릭하고 **Touch ID** 또는 **비밀번호**로 인증합니다.

## 비상 탈출

키오스크 모드에서 앱이 멈추거나 인증이 실패할 경우:
- **양쪽 Shift + Cmd + L** 키를 동시에 눌러 즉시 잠금 해제

## 주의사항

- 전원 어댑터 연결을 권장합니다 (배터리 모드에서 덮개 닫을 시 절전 진입 가능)
- 물리적 전원 버튼 강제 종료는 막을 수 없습니다

## 라이선스

MIT License

## 문서

- [기술 스택](docs/TECH_STACK.md)
- [아키텍처](docs/ARCHITECTURE.md)
- [구현 계획](docs/IMPLEMENTATION_PLAN.md)
