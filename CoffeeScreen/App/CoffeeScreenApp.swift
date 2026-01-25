import SwiftUI

@main
struct CoffeeScreenApp: App {
    @StateObject private var mainViewModel = MainViewModel()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(mainViewModel)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 400, height: 300)
    }
}
