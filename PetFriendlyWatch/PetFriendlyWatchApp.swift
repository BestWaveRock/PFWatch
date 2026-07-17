import SwiftUI

@main
struct PetFriendlyWatchApp: App {
    init() {
        // 激活 WatchConnectivity，接收 iPhone 同步的 token
        WatchSessionManager.shared.activate()
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView()
            }
        }
    }
}
