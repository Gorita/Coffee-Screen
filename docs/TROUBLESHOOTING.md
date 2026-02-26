# 트러블슈팅 가이드 (Troubleshooting Guide)

이 문서는 `Coffee-Screen` 운영 중 발생할 수 있는 문제와 그에 대한 진단 및 해결 방법을 기록합니다.

## 1. 시스템 수면 방지(Awake 모드)가 작동하지 않을 때

### 현상
- 앱 UI상으로는 "Awake" 모드가 ON 상태이나, 일정 시간 후 맥이 잠자기 모드로 진입하거나 화면이 꺼짐.
- 특히 macOS 업데이트(예: 15.x -> 15.1 등) 이후 또는 장시간 앱 방치 시 발생할 수 있음.

### 진단 방법
터미널에서 다음 명령어를 실행하여 시스템이 앱의 전원 관리 요청을 인식하고 있는지 확인합니다.

```bash
pmset -g assertions
```

**정상 상태 예시:**
출력 결과 중 `NoDisplaySleepAssertion`과 `NoIdleSleepAssertion` 항목에 `Coffee-Screen` 프로세스가 포함되어 있어야 합니다.
```text
   pid 1234(Coffee-Screen): [0x...] 00:10:00 NoIdleSleepAssertion named: "Coffee-Screen: User requested activity protection"
   pid 1234(Coffee-Screen): [0x...] 00:10:00 NoDisplaySleepAssertion named: "Coffee-Screen: User requested activity protection"
```

만약 목록에 앱이 없다면, OS가 앱을 휴면 상태(App Nap)로 전환했거나 Assertion을 강제로 해제한 것입니다.

### 권장 해결 방안 (재발 시 적용)
현재 사용 중인 `IOPMAssertion` API는 하위 레벨 API로, 최신 macOS의 전원 관리 정책(App Nap 등)에 의해 무시될 수 있습니다. 이를 더 강력한 `NSProcessInfo` 기반으로 교체해야 합니다.

**수정 대상 파일:** `CoffeeScreen/Controllers/PowerController.swift`

**교체 코드 초안:**
```swift
import Foundation
import IOKit.pwr_mgt

final class PowerController {
    private var activityObject: NSObjectProtocol?
    private var displayAssertionID: IOPMAssertionID = 0
    private var idleAssertionID: IOPMAssertionID = 0
    private(set) var isActive: Bool = false

    func startAwake() -> Result<Void, PowerError> {
        if isActive { stopAwake() }

        // 1. 고수준 활동 시작 (App Nap 방지 및 수면 방지)
        activityObject = ProcessInfo.processInfo.beginActivity(
            options: [.idleDisplaySleepDisabled, .idleSystemSleepDisabled],
            reason: "Coffee-Screen: User requested activity protection"
        )

        // 2. 하위 레벨 Assertion (보조)
        let reason = "Coffee-Screen: User requested activity protection" as CFString
        IOPMAssertionCreateWithDescription(kIOPMAssertionTypeNoDisplaySleep as CFString, reason, nil, nil, nil, 0, nil, &displayAssertionID)
        IOPMAssertionCreateWithDescription(kIOPMAssertionTypeNoIdleSleep as CFString, reason, nil, nil, nil, 0, nil, &idleAssertionID)

        isActive = true
        return .success(())
    }

    func stopAwake() {
        if let activity = activityObject {
            ProcessInfo.processInfo.endActivity(activity)
            activityObject = nil
        }
        // Assertion ID Release 로직...
        isActive = false
    }
}
```

---

## 2. 기타 확인 사항
- **App Nap 제어:** `Info.plist` 또는 앱 설정에서 "App Nap"이 활성화되어 있는지 확인하십시오. (현재는 Sandbox가 비활성화되어 있어 영향이 적으나, 향후 Sandbox 활성화 시 중요함)
- **권한 설정:** 시스템 설정 -> 개인정보 보호 및 보안 -> 전체 디스크 접근 권한 또는 자동화 권한이 필요한지 확인하십시오. (현재 전원 관리는 기본 권한으로 작동함)
