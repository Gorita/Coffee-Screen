# TODO

## 기술 부채 및 확인 필요 사항

### NSAppSleepDisabled 제거 가능 여부 확인
`#power` `#app-nap` `#testing`

**현재 상태**: Info.plist에 `NSAppSleepDisabled = true` 설정 유지 중

**배경**:
- `NSAppSleepDisabled`: App Nap 방지 (백그라운드 앱 절전 방지)
- `IOPMAssertion`: 디스플레이/시스템 수면 방지 (현재 사용 중)
- 두 설정은 서로 다른 역할을 함

**제거 가능 추정 근거**:
- 잠금 상태 → 앱이 포그라운드 → App Nap 대상 아님
- 잠금 해제 상태 → 절전 방지 필요 없음

**확인 필요한 테스트**:
1. Info.plist에서 `NSAppSleepDisabled` 제거
2. 앱 빌드 후 잠금 실행
3. 장시간(30분 이상) 잠금 상태 유지
4. 다음 항목 확인:
   - [ ] 디스플레이가 꺼지지 않는지
   - [ ] 앱이 App Nap에 의해 절전되지 않는지
   - [ ] Touch ID / PIN 인증이 정상 동작하는지
   - [ ] Activity Monitor에서 앱 상태가 "App Nap" 표시되지 않는지

**테스트 환경**:
- macOS 버전: ___
- 전원 어댑터 연결 상태: 연결 / 미연결
- 에너지 설정: 기본값

**결과**: (테스트 후 기록)
