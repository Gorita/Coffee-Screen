# TODO

## 완료된 항목

### ~~NSAppSleepDisabled 제거~~ ✅
`#power` `#app-nap`

- Info.plist에서 `NSAppSleepDisabled` 제거 완료
- IOPMAssertion으로 수면 방지 충분
- 테스트 필요: 장시간 잠금 상태에서 App Nap 발생 여부

---

## 수동 테스트 필요

### Phase 6 수동 테스트 체크리스트
`#testing` `#manual`

- [ ] 다중 모니터 환경 테스트
- [ ] 모니터 연결/해제 테스트
- [ ] 장시간 실행 테스트 (수면 방지 확인)
- [ ] Clamshell 모드 테스트
- [ ] 전체 잠금/해제 플로우 테스트
- [ ] Touch ID 인증 테스트
- [ ] PIN 인증 테스트
- [ ] 비밀번호 폴백 테스트
- [ ] 비상 탈출 키 테스트
- [ ] 비상 탈출 키 변경 및 저장 테스트

### 엣지 케이스
- [ ] Touch ID 5회 연속 실패 → 비밀번호 입력
- [ ] 인증 중 모니터 해제 → Shield 재생성
- [ ] 잠금 중 앱 강제 종료 시도 → Kiosk Mode가 차단

---

## 향후 개선 사항

### 서명된 배포 (선택)
`#deployment` `#signing`

Apple Developer Program 가입 후:
- [ ] Developer ID Application 인증서 설정
- [ ] 공증(Notarization) 스크립트 추가
- [ ] Gatekeeper 경고 없이 실행 확인
