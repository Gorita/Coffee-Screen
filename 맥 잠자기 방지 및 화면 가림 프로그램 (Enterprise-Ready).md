# **macOS 환경 기반의 장기 실행 프로세스 보장 및 화면 보안 애플리케이션 'Coffee-Screen' 개발 타당성 조사 및 아키텍처 설계 보고서 (수정안)**

## **1\. 서론 (Introduction)**

### **1.1. 배경 및 목적**

현대의 컴퓨팅 환경, 특히 인공지능(AI) 모델 학습, 대용량 데이터 렌더링 등 고부하 작업 워크플로우에서 사용자는 '작업의 연속성'과 '시스템 보안'이라는 상충되는 요구사항에 직면한다. macOS는 에너지 효율을 위해 공격적인 전원 관리 정책을 사용하며, 이는 장기 실행 프로세스의 네트워크 소켓 절단이나 작업 중단을 초래할 수 있다.

특히 \*\*기업 보안 환경(Enterprise Environment)\*\*에서는 MDM(Mobile Device Management)이나 엔드포인트 보안 솔루션(DLP, DRM, 백신 등)이 설치되어 있어, 일반적인 입력 제어 방식(Input Monitoring)이나 시스템 설정 변경이 엄격히 제한된다. 따라서 본 프로젝트는 시스템 설정에 의존하지 않고, \*\*사용자 영역(User Space)\*\*에서 표준 API만을 사용하여 '시스템 수면 방지'와 '화면/입력 차단'을 동시에 달성하는 'Coffee-Screen' 애플리케이션의 구현 계획을 수립한다.

### **1.2. 변경 사항 (Revision Note)**

초기 계획에서는 입력 차단을 위해 저수준 CGEventTap 기술을 고려하였으나, 이는 사내 보안 프로그램(Secure Input Mode 활성화)과 충돌하여 앱이 무력화될 위험이 발견되었다. 이에 따라 본 수정 계획안에서는 Apple이 공식 지원하는 \*\*키오스크 모드(Kiosk Mode API)\*\*를 채택하여 호환성과 안정성을 확보하는 방향으로 설계를 변경하였다.

## ---

**2\. 요구사항 분석 (Requirements Analysis)**

### **2.1. 핵심 기능 요구사항**

| ID | 기능명 | 상세 설명 | 구현 전략 |
| :---- | :---- | :---- | :---- |
| **FR-01** | **Awake Maintenance** | CPU, Disk, Network가 수면 모드로 진입하지 않도록 보장해야 한다. | IOKit Power Assertion |
| **FR-02** | **Visual Shield** | 모든 모니터를 불투명한 윈도우로 덮어 작업 내용을 은폐해야 한다. | NSWindow Leveling |
| **FR-03** | **Access Restriction** | 키보드/마우스 조작을 통한 시스템 이탈을 방지해야 한다. | **Kiosk Mode API** (변경됨) |
| **FR-04** | **Enterprise Safety** | 사내 보안 프로그램(DLP/Antivirus)에 의해 악성코드로 오탐되지 않아야 한다. | **Standard AppKit API** 사용 |
| **FR-05** | **Secure Unlock** | Touch ID 또는 비밀번호로 안전하게 잠금을 해제해야 한다. | LocalAuthentication |

## ---

**3\. 기술적 타당성 분석: 핵심 서브시스템**

### **3.1. 전원 관리: IOKit과 NoIdleSleep**

macOS 커널의 전원 관리를 제어하기 위해 IOKit 프레임워크를 사용한다. caffeinate CLI 도구를 래핑하는 대신, 앱 내부에서 직접 IOPMAssertionCreateWithName을 호출하여 kIOPMAssertionTypeNoIdleSleep을 생성한다.1 이는 디스플레이가 꺼지더라도 CPU와 네트워크 스택이 활성 상태를 유지하게 하여 AI 학습이나 서버 통신이 끊기는 것을 막는다.

### **3.2. 보안 입력 제어: Kiosk Mode (NSApplicationPresentationOptions)**

기업 환경에서 가장 중요한 변경점이다. CGEventTap은 '입력 모니터링' 권한을 요구하며 키로거로 인식될 수 있다. 대신 NSApplicationPresentationOptions를 사용하여 시스템 수준에서 UI 접근을 제한한다.2

* **작동 원리:** OS에게 "이 앱이 주도권을 가지며, Dock이나 메뉴 막대, 앱 전환기(Cmd+Tab)를 비활성화해달라"고 요청한다.  
* **장점:**  
  * **권한 불필요:** '손쉬운 사용'이나 '입력 모니터링' 권한이 필요 없어 보안 심사를 통과하기 쉽다.  
  * **충돌 없음:** 다른 보안 프로그램의 'Secure Input Mode'와 충돌하지 않는다.

### **3.3. 화면 은폐: Window Leveling**

CoreGraphics의 윈도우 레벨 시스템을 활용하여 CGWindowLevelKey.screenSaverWindow (Level 1000\) 이상의 우선순위를 가진 검은색 윈도우를 생성한다.4 이는 시스템 알림이나 다른 플로팅 윈도우보다 상위에 표시되어 완벽한 시각적 보안을 제공한다.

## ---

**4\. 상세 구현 계획 (Implementation Plan)**

### **4.1. 모듈 아키텍처**

1. **PowerController:** IOKit Assertion 관리.  
2. **ShieldWindowController:** 다중 모니터 감지 및 검은색 오버레이 윈도우 생성.  
3. **KioskEnforcer:** NSApp.presentationOptions 적용 및 해제.  
4. **AuthManager:** LocalAuthentication을 통한 잠금 해제 처리.

### **4.2. 단계별 구현 코드 (Swift)**

#### **Phase 1: Power Controller (수면 방지)**

Swift

import IOKit.pwr\_mgt

class PowerController {  
    var assertionID: IOPMAssertionID \= 0  
      
    func startAwake() {  
        // CPU/Network 수면 방지 (디스플레이 꺼짐은 허용하되 시스템은 계속 동작)  
        let reason \= "Coffee-Screen: AI Training in progress" as CFString  
        IOPMAssertionCreateWithName(kIOPMAssertionTypeNoIdleSleep as CFString,   
                                    IOPMAssertionLevel(kIOPMAssertionLevelOn),   
                                    reason,   
                                    &assertionID)  
    }  
      
    func stopAwake() {  
        if assertionID\!= 0 {  
            IOPMAssertionRelease(assertionID)  
            assertionID \= 0  
        }  
    }  
}

#### **Phase 2: Kiosk Enforcer (입력 및 이탈 방지)**

이 부분이 기존의 복잡한 EventTap 코드를 대체한다. 시스템 API 한 줄로 강력한 제어가 가능하다.

Swift

import AppKit

class KioskEnforcer {  
    // 저장해두었다가 복구할 이전 옵션  
    private var previousOptions: NSApplication.PresentationOptions \=

    func lockUI() {  
        previousOptions \= NSApp.presentationOptions  
          
        // 키오스크 모드 옵션 조합  
        let kioskOptions: NSApplication.PresentationOptions \=  
           .disableForceQuit,          // Cmd+Opt+Esc 비활성화  
           .disableSessionTermination, // 전원 버튼 메뉴 차단  
           .disableAppleMenu,          // 애플 메뉴 차단  
           .disableHideApplication     // Cmd+H 차단  
        \]  
          
        NSApp.presentationOptions \= kioskOptions  
        NSApp.activate(ignoringOtherApps: true) // 앱을 최상위로 강제 활성화  
          
        // 마우스 커서 숨김 (선택 사항)  
        NSCursor.hide()   
    }

    func unlockUI() {  
        NSApp.presentationOptions \= previousOptions  
        NSCursor.unhide()  
    }  
}

#### **Phase 3: Shield Window (화면 가림)**

SwiftUI 뷰를 NSWindow로 감싸서 최상위 레벨로 띄운다.

Swift

class ShieldWindow: NSWindow {  
    init(screen: NSScreen) {  
        super.init(  
            contentRect: screen.frame,  
            styleMask: \[.borderless\], // 테두리 없음  
            backing:.buffered,  
            defer: false  
        )  
          
        self.level \= NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.screenSaverWindowKey)) \+ 1)  
        self.backgroundColor \=.black  
        self.isOpaque \= true  
        self.collectionBehavior \= // 모든 데스크탑 공간에서 보임  
          
        // 잠금 해제 UI (SwiftUI View) 로드  
        self.contentView \= NSHostingView(rootView: UnlockView())  
    }  
}

#### **Phase 4: Secure Unlock (생체 인증)**

화면 중앙의 버튼을 누르거나 키보드를 입력하면 인증을 시도한다.

Swift

import LocalAuthentication

func attemptUnlock() {  
    let context \= LAContext()  
    context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "잠금을 해제하려면 인증하세요") { success, error in  
        DispatchQueue.main.async {  
            if success {  
                // KioskEnforcer.unlockUI() 호출  
                // PowerController.stopAwake() 호출  
                // 윈도우 닫기  
            }  
        }  
    }  
}

## ---

**5\. 위험 관리 및 한계점 (Risk Management)**

### **5.1. 하드웨어 전원 버튼의 한계**

NSApplicationPresentationOptions를 사용하더라도, 맥북의 물리적 전원 버튼(Touch ID 버튼)을 길게 눌러서 수행하는 **강제 종료(Hard Reset)는 소프트웨어적으로 막을 수 없다.** 이는 하드웨어 레벨의 인터럽트이기 때문이다. 하지만 이는 사용자가 의도적으로 시스템을 끄는 행위이므로, 보안 관점에서는 데이터 유출 위험보다는 데이터 손실(작업 중단) 위험에 해당한다.

### **5.2. Clamshell Mode (덮개 닫기)**

Apple Silicon (M1/M2/M3) 맥북은 전원이 연결되지 않은 상태에서 덮개를 닫으면 NoIdleSleep Assertion이 있어도 강제로 절전 모드로 들어갈 수 있다.6

* **대응책:** 앱 실행 시 "전원 어댑터를 연결하세요"라는 안내 문구를 띄우거나, 배터리 상태를 모니터링하여 전원 연결이 끊기면 경고음을 내는 기능을 추가해야 한다.

### **5.3. 비상 탈출 (Fail-Safe)**

키오스크 모드에서 앱이 멈추거나 인증 모듈이 오작동하면 사용자는 컴퓨터를 제어할 수 없게 된다(재부팅 필요).

* **권장:** 개발 단계 또는 배포 버전에서도 '숨겨진 단축키'(예: 양쪽 Shift \+ Cmd \+ L)를 구현하여 즉시 키오스크 모드를 해제하고 앱을 종료하는 안전장치를 마련해야 한다.

## ---

**6\. 결론 (Conclusion)**

업데이트된 설계안은 **기업 보안 환경에서의 호환성**을 최우선으로 고려하였다. CGEventTap 대신 **표준 Kiosk Mode API**를 사용함으로써 다음과 같은 이점을 얻는다:

1. **보안 프로그램 무력화 방지:** 사내 보안 툴의 'Secure Input' 모드와 충돌하지 않음.  
2. **권한 승인 용이:** 민감한 '입력 모니터링' 권한을 요구하지 않아 MDM 정책 위반 소지가 적음.  
3. **구현 안정성:** Apple이 권장하는 공식 API를 사용하여 OS 업데이트에 따른 호환성이 높음.

이 계획에 따라 'Coffee-Screen'을 개발하면, 보안 규정이 엄격한 회사 내에서도 안심하고 AI 학습 등 장기 작업을 수행할 수 있는 유틸리티를 확보할 수 있다.

#### **참고 자료**

1. How to programmatically prevent a Mac from going to sleep? \- Stack Overflow, 1월 25, 2026에 액세스, [https://stackoverflow.com/questions/5596319/how-to-programmatically-prevent-a-mac-from-going-to-sleep](https://stackoverflow.com/questions/5596319/how-to-programmatically-prevent-a-mac-from-going-to-sleep)  
2. disableProcessSwitching | Apple Developer Documentation, 1월 25, 2026에 액세스, [https://developer.apple.com/documentation/appkit/nsapplication/presentationoptions-swift.struct/disableprocessswitching](https://developer.apple.com/documentation/appkit/nsapplication/presentationoptions-swift.struct/disableprocessswitching)  
3. How to apply the NSApplicationPresentationOptions to an application? \- Stack Overflow, 1월 25, 2026에 액세스, [https://stackoverflow.com/questions/32810878/how-to-apply-the-nsapplicationpresentationoptions-to-an-application](https://stackoverflow.com/questions/32810878/how-to-apply-the-nsapplicationpresentationoptions-to-an-application)  
4. What is the order of \`NSWindow\` levels? \- Jim Fisher, 1월 25, 2026에 액세스, [https://jameshfisher.com/2020/08/03/what-is-the-order-of-nswindow-levels/](https://jameshfisher.com/2020/08/03/what-is-the-order-of-nswindow-levels/)  
5. Keep NSWindow front \- macos \- Stack Overflow, 1월 25, 2026에 액세스, [https://stackoverflow.com/questions/5364460/keep-nswindow-front](https://stackoverflow.com/questions/5364460/keep-nswindow-front)  
6. It still goes to sleep when I close the lid with these settings. Plz help. : r/MacOS \- Reddit, 1월 25, 2026에 액세스, [https://www.reddit.com/r/MacOS/comments/1cd4v65/it\_still\_goes\_to\_sleep\_when\_i\_close\_the\_lid\_with/](https://www.reddit.com/r/MacOS/comments/1cd4v65/it_still_goes_to_sleep_when_i_close_the_lid_with/)  
7. Mac M1 battery drained from 84% to 5% overnight with lid closed : r/MacOS \- Reddit, 1월 25, 2026에 액세스, [https://www.reddit.com/r/MacOS/comments/1n8ww2e/mac\_m1\_battery\_drained\_from\_84\_to\_5\_overnight/](https://www.reddit.com/r/MacOS/comments/1n8ww2e/mac_m1_battery_drained_from_84_to_5_overnight/)