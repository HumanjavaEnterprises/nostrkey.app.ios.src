import SwiftUI

@main
struct NostrKeepSignerApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onOpenURL { url in
                    DeepLinkHandler.handle(url: url, appState: appState)
                }
                .preferredColorScheme(.dark)
        }
    }
}
