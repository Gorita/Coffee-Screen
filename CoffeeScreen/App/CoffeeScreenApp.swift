import SwiftUI
import CoreText

@main
struct CoffeeScreenApp: App {

    init() {
        registerFonts()
    }

    private func registerFonts() {
        let fonts = [
            ("PressStart2P-Regular", "ttf"),
            ("Silkscreen-Regular", "ttf"),
            ("VT323-Regular", "ttf")
        ]

        for (name, ext) in fonts {
            if let fontURL = Bundle.main.url(forResource: name, withExtension: ext) {
                var error: Unmanaged<CFError>?
                let success = CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error)
                if !success {
                    print("Failed to register font: \(name)")
                } else {
                    print("Registered font: \(name)")
                }
            } else {
                print("Font not found: \(name).\(ext)")
            }
        }
    }
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var mainViewModel = MainViewModel()

    var body: some Scene {
        WindowGroup(id: "main") {
            MainView()
                .environmentObject(mainViewModel)
                .background(WindowAccessor())
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 400, height: 300)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}

/// 윈도우에 접근하여 닫기 동작을 숨기기로 변경
struct WindowAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                // X 버튼 클릭 시 숨기기 (닫지 않음)
                window.standardWindowButton(.closeButton)?.target = context.coordinator
                window.standardWindowButton(.closeButton)?.action = #selector(Coordinator.hideWindow)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject {
        @objc func hideWindow() {
            NSApp.keyWindow?.orderOut(nil)
        }
    }
}

/// 앱 델리게이트
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            for window in sender.windows where !(window is ShieldWindow) {
                window.makeKeyAndOrderFront(self)
                return true
            }
        }
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
